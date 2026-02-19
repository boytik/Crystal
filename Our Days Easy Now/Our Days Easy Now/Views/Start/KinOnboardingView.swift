// KinOnboardingView.swift
// Our Days: Easy Now
// Onboarding — 4 steps with animations, English UI, family setup

import SwiftUI

// MARK: - Main Onboarding Container

struct KinOnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var slideDirection: Edge = .trailing

    // Onboarding data
    @State private var draftSouls: [KinSoul] = [
        KinSoul(nestName: "Me", kinRole: .parent, spiritEmoji: "🧡", colorSeed: 0),
        KinSoul(nestName: "Partner", kinRole: .parent, spiritEmoji: "💙", colorSeed: 1),
    ]
    @State private var selectedDeedIds: Set<UUID> = Set(HearthDeedFactory.createDefaults().map { $0.id })
    @State private var availableDeeds: [HearthDeed] = HearthDeedFactory.createDefaults()

    private let totalSteps = 4

    var body: some View {
        ZStack {
            AnimatedEmberSky()

            VStack(spacing: 0) {
                // Step indicator
                stepIndicator
                    .padding(.top, 16)

                // Step content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    teamStep.tag(1)
                    deedsStep.tag(2)
                    firstTapStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? NestPalette.hearthGold : NestPalette.moonThread)
                    .frame(width: index == currentStep ? 28 : 10, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        OnboardingWelcomeStep(onNext: { advanceStep() })
    }

    // MARK: - Step 1: Team Setup

    private var teamStep: some View {
        OnboardingTeamStep(
            draftSouls: $draftSouls,
            onNext: { advanceStep() },
            onBack: { goBack() }
        )
    }

    // MARK: - Step 2: Deeds Picker

    private var deedsStep: some View {
        OnboardingDeedsStep(
            availableDeeds: $availableDeeds,
            selectedDeedIds: $selectedDeedIds,
            onNext: { advanceStep() },
            onBack: { goBack() }
        )
    }

    // MARK: - Step 3: First Tap

    private var firstTapStep: some View {
        OnboardingFirstTapStep(
            souls: draftSouls,
            deeds: availableDeeds.filter { selectedDeedIds.contains($0.id) },
            onFinish: { finalizeOnboarding() }
        )
    }

    // MARK: - Navigation

    private func advanceStep() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep += 1
        }
    }

    private func goBack() {
        guard currentStep > 0 else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep -= 1
        }
    }

    private func finalizeOnboarding() {
        let vault = HearthVault.shared

        // Save members
        for soul in draftSouls where !soul.nestName.trimmingCharacters(in: .whitespaces).isEmpty {
            vault.addKinSoul(soul)
        }

        // Save selected deeds only
        let selected = availableDeeds.filter { selectedDeedIds.contains($0.id) }
        for deed in selected {
            vault.addHearthDeed(deed)
        }

        // Clear default deeds and replace
        vault.hearthDeeds = selected

        onComplete()
    }
}

// MARK: - Step 0: Welcome

struct OnboardingWelcomeStep: View {
    let onNext: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var cardsAppear: Bool = false
    @State private var ctaOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero icon
            ZStack {
                Circle()
                    .fill(NestPalette.hearthGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            Spacer().frame(height: 28)

            Text("Track what matters,\ntogether.")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)
                .multilineTextAlignment(.center)
                .opacity(iconOpacity)

            Spacer().frame(height: 12)

            Text("Quick logs for daily care and chores —\nsee every contribution without the arguments.")
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(iconOpacity)

            Spacer().frame(height: 36)

            // Promise cards
            VStack(spacing: 12) {
                promiseCard(icon: "hand.tap.fill", text: "1 tap = 1 moment logged")
                promiseCard(icon: "chart.pie.fill", text: "Weekly balance without toxic scores")
                promiseCard(icon: "lock.shield.fill", text: "Your data stays on device")
            }
            .opacity(cardsAppear ? 1 : 0)
            .offset(y: cardsAppear ? 0 : 20)

            Spacer()

            // CTA
            Button(action: onNext) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(HearthButtonStyle())
            .opacity(ctaOpacity)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                cardsAppear = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
                ctaOpacity = 1
            }
        }
    }

    private func promiseCard(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundColor(NestPalette.hearthGold)
                .frame(width: 32)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundColor(NestPalette.snowfall)

            Spacer()
        }
        .padding(14)
        .background(NestPalette.blanketCharcoal.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }
}

// MARK: - Step 1: Team Setup

struct OnboardingTeamStep: View {
    @Binding var draftSouls: [KinSoul]
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var editingIndex: Int? = nil
    @State private var nameInput: String = ""

    private let emojiOptions = ["🧡", "💙", "💚", "💜", "🧡", "💛", "🤎", "🩷", "🖤", "🩵", "❤️", "🤍"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text("Your Team")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)

            Text("Who takes care of things at home?")
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)
                .padding(.top, 6)

            Spacer().frame(height: 28)

            // Members list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(draftSouls.enumerated()), id: \.element.id) { index, soul in
                        memberRow(soul: soul, index: index)
                    }

                    // Add member button
                    if draftSouls.count < 6 {
                        Button(action: addMember) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(NestPalette.hearthGold)
                                Text("Add Member")
                                    .foregroundColor(NestPalette.duskWhisper)
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(NestPalette.blanketCharcoal.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    .foregroundColor(NestPalette.moonThread)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Text("You can change this later")
                .font(.caption)
                .foregroundColor(NestPalette.shadowMurmur)
                .padding(.bottom, 12)

            // Navigation
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                }
                .buttonStyle(MoonlitButtonStyle())

                Button(action: onNext) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(HearthButtonStyle())
                .disabled(draftSouls.filter { !$0.nestName.isEmpty }.count < 1)
                .opacity(draftSouls.filter { !$0.nestName.isEmpty }.count < 1 ? 0.5 : 1)
            }
            .padding(.bottom, 48)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
            }
        }
    }

    private func memberRow(soul: KinSoul, index: Int) -> some View {
        HStack(spacing: 14) {
            // Emoji avatar button
            Button {
                cycleEmoji(at: index)
            } label: {
                Text(soul.spiritEmoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(NestPalette.moonThread.opacity(0.4))
                    .cornerRadius(25)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Editable name
                TextField("Name", text: Binding(
                    get: { draftSouls[safe: index]?.nestName ?? "" },
                    set: { newVal in
                        if draftSouls.indices.contains(index) {
                            draftSouls[index].nestName = newVal
                        }
                    }
                ))
                .font(.body.weight(.semibold))
                .foregroundColor(NestPalette.snowfall)
                .textFieldStyle(.plain)

                // Role picker
                HStack(spacing: 8) {
                    ForEach(KinRole.allCases.prefix(3)) { role in
                        rolePill(role: role, isSelected: soul.kinRole == role, index: index)
                    }
                }
            }

            Spacer()

            // Remove (if more than 1)
            if draftSouls.count > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        draftSouls.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(NestPalette.shadowMurmur)
                        .font(.title3)
                }
            }
        }
        .padding(14)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }

    private func rolePill(role: KinRole, isSelected: Bool, index: Int) -> some View {
        Button {
            draftSouls[index].kinRole = role
        } label: {
            Text(role.rawValue)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? NestPalette.hearthGold.opacity(0.2) : NestPalette.moonThread.opacity(0.3))
                .foregroundColor(isSelected ? NestPalette.hearthGold : NestPalette.duskWhisper)
                .cornerRadius(6)
        }
    }

    private func addMember() {
        let newIndex = draftSouls.count
        let emoji = emojiOptions[newIndex % emojiOptions.count]
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            draftSouls.append(KinSoul(
                nestName: "",
                kinRole: .other,
                spiritEmoji: emoji,
                colorSeed: newIndex
            ))
        }
    }

    private func cycleEmoji(at index: Int) {
        guard draftSouls.indices.contains(index) else { return }
        let current = draftSouls[index].spiritEmoji
        if let idx = emojiOptions.firstIndex(of: current) {
            let next = emojiOptions[(idx + 1) % emojiOptions.count]
            draftSouls[index].spiritEmoji = next
        } else {
            draftSouls[index].spiritEmoji = emojiOptions[0]
        }
    }
}

// MARK: - Step 2: Deeds Picker

struct OnboardingDeedsStep: View {
    @Binding var availableDeeds: [HearthDeed]
    @Binding var selectedDeedIds: Set<UUID>
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var customDeedName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text("Quick Actions")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)

            Text("Pick the things you actually do daily")
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)
                .padding(.top, 6)

            Spacer().frame(height: 24)

            ScrollView {
                // Deed grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12) {
                    ForEach(availableDeeds) { deed in
                        deedCard(deed)
                    }
                }
                .padding(.horizontal, 24)

                // Add custom deed
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .foregroundColor(NestPalette.hearthGold)
                            .font(.caption.bold())

                        TextField("Add your own...", text: $customDeedName)
                            .font(.subheadline)
                            .foregroundColor(NestPalette.snowfall)
                            .textFieldStyle(.plain)

                        if !customDeedName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                addCustomDeed()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(NestPalette.hearthGold)
                            }
                        }
                    }
                    .padding(12)
                    .background(NestPalette.blanketCharcoal.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundColor(NestPalette.moonThread)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Text("Keep only what you'll really track")
                    .font(.caption)
                    .foregroundColor(NestPalette.shadowMurmur)
                    .padding(.top, 10)
            }

            Spacer()

            // Navigation
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                }
                .buttonStyle(MoonlitButtonStyle())

                Button(action: onNext) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(HearthButtonStyle())
                .disabled(selectedDeedIds.isEmpty)
                .opacity(selectedDeedIds.isEmpty ? 0.5 : 1)
            }
            .padding(.bottom, 48)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
            }
        }
    }

    private func deedCard(_ deed: HearthDeed) -> some View {
        let isSelected = selectedDeedIds.contains(deed.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedDeedIds.remove(deed.id)
                } else {
                    selectedDeedIds.insert(deed.id)
                }
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: deed.deedIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? NestPalette.hearthGold : NestPalette.duskWhisper)

                Text(deed.deedName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? NestPalette.snowfall : NestPalette.duskWhisper)

                // Domain tag
                Text(deed.deedDomain.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(NestPalette.shadowMurmur)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(NestPalette.moonThread.opacity(0.4))
                    .cornerRadius(4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? NestPalette.hearthGold.opacity(0.1) : NestPalette.blanketCharcoal)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? NestPalette.hearthGold.opacity(0.5) : NestPalette.moonThread, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
    }

    private func addCustomDeed() {
        let name = customDeedName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let deed = HearthDeed(
            deedName: name,
            deedIcon: "star.fill",
            deedDomain: .custom,
            sortOrder: availableDeeds.count,
            isDefault: false
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            availableDeeds.append(deed)
            selectedDeedIds.insert(deed.id)
        }
        customDeedName = ""
    }
}

// MARK: - Step 3: First Tap (Try It Now)

struct OnboardingFirstTapStep: View {
    let souls: [KinSoul]
    let deeds: [HearthDeed]
    let onFinish: () -> Void

    @State private var selectedDeed: HearthDeed?
    @State private var selectedSoul: KinSoul?
    @State private var showSuccess: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var successScale: CGFloat = 0.3
    @State private var confettiVisible: Bool = false

    private var sampleDeed: HearthDeed {
        deeds.first ?? HearthDeedFactory.createDefaults()[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if !showSuccess {
                tryItContent
            } else {
                successContent
            }

            Spacer()
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
            }
        }
    }

    private var tryItContent: some View {
        VStack(spacing: 24) {
            Text("Try it now!")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)

            Text("Tap an action, then choose who did it")
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)

            // Deed button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDeed = sampleDeed
                }
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: sampleDeed.deedIcon)
                        .font(.system(size: 40))
                        .foregroundColor(
                            selectedDeed != nil ? NestPalette.hearthGold : NestPalette.duskWhisper
                        )

                    Text(sampleDeed.deedName)
                        .font(.headline)
                        .foregroundColor(NestPalette.snowfall)
                }
                .frame(width: 140, height: 120)
                .background(
                    selectedDeed != nil
                        ? NestPalette.hearthGold.opacity(0.12)
                        : NestPalette.blanketCharcoal
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            selectedDeed != nil
                                ? NestPalette.hearthGold
                                : NestPalette.moonThread,
                            lineWidth: selectedDeed != nil ? 2 : 0.5
                        )
                )
            }
            .scaleEffect(selectedDeed != nil ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedDeed != nil)

            // Member picker (appears after deed tap)
            if selectedDeed != nil {
                VStack(spacing: 12) {
                    Text("Who did it?")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(NestPalette.duskWhisper)

                    HStack(spacing: 16) {
                        ForEach(souls.prefix(4)) { soul in
                            Button {
                                selectedSoul = soul
                                logFirstMoment(soul: soul)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(soul.spiritEmoji)
                                        .font(.system(size: 36))
                                        .frame(width: 60, height: 60)
                                        .background(NestPalette.moonThread.opacity(0.4))
                                        .cornerRadius(30)

                                    Text(soul.nestName)
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(NestPalette.duskWhisper)
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
    }

    private var successContent: some View {
        VStack(spacing: 20) {
            ZStack {
                // Confetti sparks
                if confettiVisible {
                    ForEach(0..<8, id: \.self) { i in
                        Circle()
                            .fill(NestPalette.kinColors[i % NestPalette.kinColors.count])
                            .frame(width: 6, height: 6)
                            .offset(confettiOffset(index: i))
                            .opacity(confettiVisible ? 0 : 1)
                    }
                }

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(NestPalette.harmonyMoss)
                    .scaleEffect(successScale)
            }

            Text("Moment logged!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)

            if let soul = selectedSoul {
                Text("\(soul.spiritEmoji) \(soul.nestName) — \(sampleDeed.deedName)")
                    .font(.subheadline)
                    .foregroundColor(NestPalette.duskWhisper)
            }

            Text("That's all it takes. One tap.")
                .font(.subheadline)
                .foregroundColor(NestPalette.shadowMurmur)
                .padding(.top, 8)

            Spacer().frame(height: 24)

            Button(action: onFinish) {
                HStack {
                    Text("Open Hearth")
                    Image(systemName: "flame.fill")
                }
            }
            .buttonStyle(HearthButtonStyle())
        }
        .padding(.horizontal, 24)
    }

    private func confettiOffset(index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 8.0) * .pi / 180
        let radius: CGFloat = confettiVisible ? 80 : 0
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func logFirstMoment(soul: KinSoul) {
        // Log the moment
        let moment = EmberMoment(deedId: sampleDeed.id, kinSoulId: soul.id)
        HearthVault.shared.logEmberMoment(moment)

        // Show success
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showSuccess = true
            successScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.7)) {
                confettiVisible = true
            }
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
