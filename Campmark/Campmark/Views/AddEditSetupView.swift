import SwiftUI
import SwiftData

struct AddEditSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var setup: CampingSetup?

    @State private var name: String = ""
    @State private var costText: String = ""
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Setup Name") {
                    TextField("e.g. Ultralight Backpack", text: $name)
                }

                Section("Gear Cost") {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $costText)
                            .keyboardType(.decimalPad)
                    }
                    Text("Total cost of your camping gear for this setup.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(setup == nil ? "New Setup" : "Edit Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let setup {
                    name = setup.name
                    costText = String(format: "%.2f", setup.cost)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let cost = Double(costText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard cost >= 0 else {
            saveError = "Cost must be a positive number."
            return
        }
        saveError = nil

        if let setup {
            setup.name = trimmedName
            setup.cost = cost
        } else {
            let newSetup = CampingSetup(name: trimmedName, cost: cost)
            modelContext.insert(newSetup)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
        }
    }
}
