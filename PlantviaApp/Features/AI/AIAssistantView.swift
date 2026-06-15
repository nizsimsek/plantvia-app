//
//  AIAssistantView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI
import PhotosUI
import UIKit

struct AIAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    var plantId: Int?
    var startQuestion: String = ""
    var showsCloseButton = false
    
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "I am Plantvia AI. Upload a clear plant photo and ask your question; I will review visible leaves, soil, light clues, watering routine, and care risks without making a definitive diagnosis.".localized, fromTheUser: false)
    ]
    @State private var question = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @FocusState private var isInputFocused: Bool
    @State private var dailyRemaining: Int? = nil
    @State private var dailyLimit: Int = 50
    
    var body: some View {
        Group {
            if !connectivityStore.isOnline {
                OfflineAILockView()
            } else if subscriptionStore.isPremiumActive {
                chatContent
            } else {
                PremiumAILockView()
            }
        }
        .navigationTitle("AI Plant Assistant".localized)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Close".localized) {
                    isInputFocused = false
                }
            }
        }
        .task {
            if connectivityStore.isOnline, let updatedUser = await subscriptionStore.refreshSubscriptionStatus(token: authStore.authToken) {
                authStore.updateActiveUser(updatedUser)
            }
            if connectivityStore.isOnline, subscriptionStore.isPremiumActive,
               let status = try? await container.aiService.fetchAiStatus(token: authStore.authToken) {
                dailyRemaining = status.remaining
                dailyLimit = status.limit
            }
        }
        .onAppear {
            if !startQuestion.isEmpty && question.isEmpty { question = startQuestion }
        }
        .onChange(of: selectedPhoto) { _, selectedItem in
            Task {
                selectedImageData = await loadNormalizedImageData(from: selectedItem)
            }
        }
    }
    
    private var chatContent: some View {
        ZStack {
            PremiumGradientBackground()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        aiHeader
                        imageArea
                        questionChips
                        ForEach(messages) { message in
                            messageBubble(message)
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(.red)
                        }
                        if isSubmitting {
                            ProgressView("AI is analyzing...".localized)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                
                inputBar
                    .padding()
                    .background(.regularMaterial)
            }
        }
    }
    
    private var aiHeader: some View {
        PlantviaSurface {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(colors: [.plantviaLavender, .plantviaPrimary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Plant Assistant".localized)
                        .font(.headline)
                    Text("Upload a photo and ask for focused care guidance.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let remaining = dailyRemaining {
                    AIQuotaBadge(remaining: remaining, limit: dailyLimit)
                }
            }
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your plant".localized, text: $question, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.plantviaCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Button {
                Task { await sendQuestion() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(
                        question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                        ? Color.secondary.opacity(0.45)
                        : Color.plantviaPrimary
                    )
            }
            .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
    }
    
    private var imageArea: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: selectedImageData == nil ? "photo.badge.plus" : "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.plantviaPrimary)
                    VStack(alignment: .leading) {
                        Text(selectedImageData == nil ? "Upload photo".localized : "Photo selected".localized)
                            .font(.headline)
                        Text("Make sure leaves, soil, and the overall plant are clear.".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                if let selectedImageData, let image = UIImage(data: selectedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                self.selectedPhoto = nil
                                self.selectedImageData = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .black.opacity(0.45))
                                    .padding(10)
                            }
                            .buttonStyle(.plain)
                        }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var questionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(["Why are the leaves yellow?", "Is the soil dry?", "How much water should I give?", "Is this plant healthy?"], id: \.self) { chip in
                    Button(chip.localized) { question = chip.localized }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.plantviaMint.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.fromTheUser { Spacer() }
            Text(message.text)
                .padding(14)
                .background(message.fromTheUser ? Color.plantviaPrimary : Color.plantviaCard)
                .foregroundStyle(message.fromTheUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 310, alignment: message.fromTheUser ? .trailing : .leading)
            if !message.fromTheUser { Spacer() }
        }
    }
    
    private func sendQuestion() async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        isInputFocused = false
        messages.append(ChatMessage(text: trimmedQuestion, fromTheUser: true))
        question = ""
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        do {
            let answer = try await container.aiService.performPlantAnalysis(question: trimmedQuestion, plantId: plantId, imageData: selectedImageData, token: authStore.authToken)
            messages.append(ChatMessage(text: formattedAnswer(answer), fromTheUser: false))
            if let r = answer.remaining { dailyRemaining = r }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func formattedAnswer(_ answer: AIAnalysisAnswer) -> String {
        let suggestions = answer.suggestions
            .map { "• \($0)" }
            .joined(separator: "\n")
        
        return """
        \(answer.answer)
        
        \("Suggestions".localized):
        \(suggestions)
        
        \(L10n.format("Confidence: %@", answer.confidenceLevel))
        \(answer.warning)
        """
    }
    
    private func loadNormalizedImageData(from item: PhotosPickerItem?) async -> Data? {
        guard let rawData = try? await item?.loadTransferable(type: Data.self),
              let image = UIImage(data: rawData) else {
            return nil
        }
        
        return image.jpegData(compressionQuality: 0.82)
    }
}

struct OfflineAILockView: View {
    var body: some View {
        ContentUnavailableView(
            "AI requires internet connection".localized,
            systemImage: "wifi.slash",
            description: Text("Photo analysis and care answers are available when you are back online.".localized)
        )
    }
}

private struct AIQuotaBadge: View {
    let remaining: Int
    let limit: Int

    private var color: Color {
        let ratio = Double(remaining) / Double(max(limit, 1))
        if ratio > 0.4 { return .green }
        if ratio > 0.2 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(remaining)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text("left today".localized)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct PremiumAILockView: View {
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            VStack(spacing: 22) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Color.plantviaPrimary)
                
                VStack(spacing: 8) {
                    Text("AI Plant Assistant is Premium only".localized)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Photo-based plant analysis, care suggestions, and smart Q&A are available only for Premium users.".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("Leaf and soil feedback from photos".localized, systemImage: "camera.macro")
                    Label("Safe care suggestions and warnings".localized, systemImage: "text.bubble.fill")
                    Label("Ad-free advanced care experience".localized, systemImage: "crown.fill")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                NavigationLink(destination: PremiumView()) {
                    Label("Go Premium".localized, systemImage: "crown.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(Color.plantviaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(24)
        }
    }
}
