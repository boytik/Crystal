// NestSheetViews.swift
// Our Days: Easy Now
// All modal sheets — separated from ViewModels per architecture rules

import SwiftUI

// MARK: - Who Did Sheet (pick member for a deed)

struct WhoDidSheet: View {
    let deed: HearthDeed
    @EnvironmentObject var coordinator: NestCoordinator
    @ObservedObject private var vault = HearthVault.shared

    @State private var timeMode: WhoDidTimeMode = .now
    @State private var customTime: Date = Date()
    @State private var tinyNote: String = ""
    @State private var loggedSoulId: UUID?
    @State private var showSuccess: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Deed header
                        deedHeader

                        // Member grid
                        memberGrid

                        // Time mode
                        timePicker

                        // Note
                        noteField

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }

                // Success overlay
                if showSuccess {
                    successOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("Who did it?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private var deedHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: deed.deedIcon)
                .font(.system(size: 36))
                .foregroundColor(NestPalette.hearthGold)

            Text(deed.deedName)
                .font(.title3.weight(.bold))
                .foregroundColor(NestPalette.snowfall)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(NestPalette.hearthGold.opacity(0.08))
        .cornerRadius(16)
    }

    private var memberGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose who")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(vault.activeKinSouls) { soul in
                    Button {
                        confirmLog(soul: soul)
                    } label: {
                        VStack(spacing: 6) {
                            Text(soul.spiritEmoji)
                                .font(.system(size: 36))
                                .frame(width: 56, height: 56)
                                .background(NestPalette.kinColor(at: soul.colorSeed).opacity(0.15))
                                .cornerRadius(28)

                            Text(soul.nestName)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(NestPalette.snowfall)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(NestPalette.blanketCharcoal)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(NestPalette.moonThread, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(DeedTapStyle())
                }
            }
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            HStack(spacing: 0) {
                ForEach(WhoDidTimeMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            timeMode = mode
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(
                                timeMode == mode ? NestPalette.emberNight : NestPalette.duskWhisper
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                timeMode == mode ? NestPalette.hearthGold : Color.clear
                            )
                    }
                }
            }
            .background(NestPalette.blanketCharcoal)
            .cornerRadius(10)

            if timeMode == .custom {
                DatePicker("", selection: $customTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(NestPalette.hearthGold)
                    .colorScheme(.dark)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick note (optional)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            TextField("e.g. before bedtime, quick one...", text: $tinyNote)
                .font(.subheadline)
                .foregroundColor(NestPalette.snowfall)
                .padding(12)
                .background(NestPalette.blanketCharcoal)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(NestPalette.moonThread, lineWidth: 0.5)
                )

            Text("You can add details later")
                .font(.caption2)
                .foregroundColor(NestPalette.shadowMurmur)
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(NestPalette.harmonyMoss)

            Text("Moment logged!")
                .font(.headline)
                .foregroundColor(NestPalette.snowfall)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NestPalette.cradleDark.opacity(0.92))
    }

    private func confirmLog(soul: KinSoul) {
        let time = timeMode == .now ? Date() : customTime
        let note = tinyNote.trimmingCharacters(in: .whitespaces)

        let moment = EmberMoment(
            deedId: deed.id,
            kinSoulId: soul.id,
            happenedAt: time,
            tinyNote: note.isEmpty ? nil : note
        )
        vault.logEmberMoment(moment)

        loggedSoulId = soul.id
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }

        coordinator.showMomentLogged(deedName: deed.deedName, kinName: soul.nestName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

enum WhoDidTimeMode: String, CaseIterable, Identifiable {
    case now = "Now"
    case custom = "Other Time"
    var id: String { rawValue }
}

// MARK: - Moment Detail Sheet

struct MomentDetailSheet: View {
    let moment: EmberMoment
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var editedNote: String
    @State private var editedTime: Date

    init(moment: EmberMoment) {
        self.moment = moment
        _editedNote = State(initialValue: moment.tinyNote ?? "")
        _editedTime = State(initialValue: moment.happenedAt)
    }

    private var soul: KinSoul? {
        vault.kinSouls.first(where: { $0.id == moment.kinSoulId })
    }

    private var deed: HearthDeed? {
        vault.hearthDeeds.first(where: { $0.id == moment.deedId })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Text(soul?.spiritEmoji ?? "❓")
                                .font(.system(size: 48))

                            Text(soul?.nestName ?? "Unknown")
                                .font(.title3.weight(.bold))
                                .foregroundColor(NestPalette.snowfall)

                            HStack(spacing: 6) {
                                Image(systemName: deed?.deedIcon ?? "questionmark")
                                    .foregroundColor(NestPalette.hearthGold)
                                Text(deed?.deedName ?? "Unknown")
                                    .foregroundColor(NestPalette.duskWhisper)
                            }
                            .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)

                        // Time edit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            DatePicker("", selection: $editedTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(NestPalette.hearthGold)
                                .colorScheme(.dark)
                        }
                        .padding(.horizontal, 20)

                        // Note edit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            TextField("Add a note...", text: $editedNote)
                                .font(.subheadline)
                                .foregroundColor(NestPalette.snowfall)
                                .padding(12)
                                .background(NestPalette.blanketCharcoal)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)

                        // Gratitude status
                        if moment.hasGratitude {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(NestPalette.bondSpark)
                                Text("This moment was thanked 💛")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(NestPalette.bondSpark)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(NestPalette.bondSpark.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }

                        // Save button
                        Button {
                            saveChanges()
                        } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())
                        .padding(.horizontal, 20)

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Moment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private func saveChanges() {
        var updated = moment
        updated.happenedAt = editedTime
        let trimmed = editedNote.trimmingCharacters(in: .whitespaces)
        updated.tinyNote = trimmed.isEmpty ? nil : trimmed
        vault.updateEmberMoment(updated)
        dismiss()
    }
}

// MARK: - Add Kin Soul Sheet

struct AddKinSoulSheet: View {
    @EnvironmentObject var coordinator: NestCoordinator
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String = ""
    @State private var selectedRole: KinRole = .parent
    @State private var selectedEmoji: String = "🧡"

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Emoji picker
                        VStack(spacing: 10) {
                            Text(selectedEmoji)
                                .font(.system(size: 56))
                                .frame(width: 80, height: 80)
                                .background(NestPalette.hearthGold.opacity(0.12))
                                .cornerRadius(40)

                            Text("Tap to change")
                                .font(.caption2)
                                .foregroundColor(NestPalette.shadowMurmur)
                        }

                        emojiGrid(SpiritEmojiCatalog.memberEmojis) { emoji in
                            selectedEmoji = emoji
                        }

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            TextField("Family member name", text: $nameInput)
                                .font(.body)
                                .foregroundColor(NestPalette.snowfall)
                                .padding(12)
                                .background(NestPalette.blanketCharcoal)
                                .cornerRadius(10)
                        }

                        // Role
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            rolePickerGrid
                        }

                        // Save
                        Button {
                            save()
                        } label: {
                            Text("Add Member")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())
                        .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private var rolePickerGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(KinRole.allCases) { role in
                Button {
                    selectedRole = role
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: role.spiritIcon)
                            .font(.caption)
                        Text(role.rawValue)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(
                        selectedRole == role ? NestPalette.emberNight : NestPalette.duskWhisper
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedRole == role ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                    )
                    .cornerRadius(8)
                }
            }
        }
    }

    private func save() {
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let soul = KinSoul(
            nestName: name,
            kinRole: selectedRole,
            spiritEmoji: selectedEmoji,
            colorSeed: vault.kinSouls.count
        )
        vault.addKinSoul(soul)
        dismiss()
    }
}

// MARK: - Edit Kin Soul Sheet

struct EditKinSoulSheet: View {
    let soul: KinSoul
    @ObservedObject private var vault = HearthVault.shared
    @EnvironmentObject var coordinator: NestCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String
    @State private var selectedRole: KinRole
    @State private var selectedEmoji: String

    init(soul: KinSoul) {
        self.soul = soul
        _nameInput = State(initialValue: soul.nestName)
        _selectedRole = State(initialValue: soul.kinRole)
        _selectedEmoji = State(initialValue: soul.spiritEmoji)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text(selectedEmoji)
                            .font(.system(size: 56))
                            .frame(width: 80, height: 80)
                            .background(NestPalette.kinColor(at: soul.colorSeed).opacity(0.15))
                            .cornerRadius(40)

                        emojiGrid(SpiritEmojiCatalog.memberEmojis) { emoji in
                            selectedEmoji = emoji
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            TextField("Name", text: $nameInput)
                                .font(.body)
                                .foregroundColor(NestPalette.snowfall)
                                .padding(12)
                                .background(NestPalette.blanketCharcoal)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(KinRole.allCases) { role in
                                    Button {
                                        selectedRole = role
                                    } label: {
                                        Text(role.rawValue)
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(
                                                selectedRole == role ? NestPalette.emberNight : NestPalette.duskWhisper
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedRole == role ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Button { saveEdit() } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())

                        Button {
                            coordinator.confirmArchiveMember(soul)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "archivebox")
                                Text("Archive Member")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(NestPalette.nudgeRose)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private func saveEdit() {
        var updated = soul
        updated.nestName = nameInput.trimmingCharacters(in: .whitespaces)
        updated.kinRole = selectedRole
        updated.spiritEmoji = selectedEmoji
        vault.updateKinSoul(updated)
        dismiss()
    }
}

// MARK: - Add Deed Sheet

struct AddDeedSheet: View {
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedDomain: DeedDomain = .household

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        VStack(spacing: 8) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 36))
                                .foregroundColor(NestPalette.hearthGold)

                            Text(nameInput.isEmpty ? "New Action" : nameInput)
                                .font(.headline)
                                .foregroundColor(NestPalette.snowfall)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(NestPalette.hearthGold.opacity(0.06))
                        .cornerRadius(16)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Action Name")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            TextField("e.g. Doctor visit, Homework...", text: $nameInput)
                                .font(.body)
                                .foregroundColor(NestPalette.snowfall)
                                .padding(12)
                                .background(NestPalette.blanketCharcoal)
                                .cornerRadius(10)
                        }

                        // Icon picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Icon")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            iconPickerGrid
                        }

                        // Domain picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            HStack(spacing: 8) {
                                ForEach(DeedDomain.allCases) { domain in
                                    Button {
                                        selectedDomain = domain
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: domain.tinyIcon)
                                                .font(.caption2)
                                            Text(domain.rawValue)
                                                .font(.caption.weight(.medium))
                                        }
                                        .foregroundColor(
                                            selectedDomain == domain ? NestPalette.emberNight : NestPalette.duskWhisper
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedDomain == domain ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Button { save() } label: {
                            Text("Add Action")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())
                        .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private var iconPickerGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(SpiritEmojiCatalog.deedIcons, id: \.self) { icon in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedIcon = icon
                    }
                } label: {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(
                            selectedIcon == icon ? NestPalette.emberNight : NestPalette.duskWhisper
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            selectedIcon == icon ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                        )
                        .cornerRadius(8)
                }
            }
        }
    }

    private func save() {
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let deed = HearthDeed(
            deedName: name,
            deedIcon: selectedIcon,
            deedDomain: selectedDomain,
            sortOrder: vault.hearthDeeds.count,
            isDefault: false
        )
        vault.addHearthDeed(deed)
        dismiss()
    }
}

// MARK: - Edit Deed Sheet

struct EditDeedSheet: View {
    let deed: HearthDeed
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String
    @State private var selectedIcon: String
    @State private var selectedDomain: DeedDomain

    init(deed: HearthDeed) {
        self.deed = deed
        _nameInput = State(initialValue: deed.deedName)
        _selectedIcon = State(initialValue: deed.deedIcon)
        _selectedDomain = State(initialValue: deed.deedDomain)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 36))
                                .foregroundColor(NestPalette.hearthGold)

                            Text(nameInput.isEmpty ? deed.deedName : nameInput)
                                .font(.headline)
                                .foregroundColor(NestPalette.snowfall)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(NestPalette.hearthGold.opacity(0.06))
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            TextField("Action name", text: $nameInput)
                                .font(.body)
                                .foregroundColor(NestPalette.snowfall)
                                .padding(12)
                                .background(NestPalette.blanketCharcoal)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Icon")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                                ForEach(SpiritEmojiCatalog.deedIcons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.caption)
                                            .foregroundColor(
                                                selectedIcon == icon ? NestPalette.emberNight : NestPalette.duskWhisper
                                            )
                                            .frame(width: 36, height: 36)
                                            .background(
                                                selectedIcon == icon ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)

                            HStack(spacing: 8) {
                                ForEach(DeedDomain.allCases) { domain in
                                    Button {
                                        selectedDomain = domain
                                    } label: {
                                        Text(domain.rawValue)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(
                                                selectedDomain == domain ? NestPalette.emberNight : NestPalette.duskWhisper
                                            )
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedDomain == domain ? NestPalette.hearthGold : NestPalette.blanketCharcoal
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Button { saveEdit() } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())

                        Button {
                            vault.archiveHearthDeed(id: deed.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "archivebox")
                                Text("Archive Action")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(NestPalette.nudgeRose)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private func saveEdit() {
        var updated = deed
        updated.deedName = nameInput.trimmingCharacters(in: .whitespaces)
        updated.deedIcon = selectedIcon
        updated.deedDomain = selectedDomain
        vault.updateHearthDeed(updated)
        dismiss()
    }
}

// MARK: - Shared Emoji Grid

func emojiGrid(_ emojis: [String], onSelect: @escaping (String) -> Void) -> some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
        ForEach(emojis, id: \.self) { emoji in
            Button {
                onSelect(emoji)
            } label: {
                Text(emoji)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(NestPalette.blanketCharcoal)
                    .cornerRadius(8)
            }
        }
    }
}
