import SwiftUI
import SwiftData

struct SetupListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CampingSetup.name) private var setups: [CampingSetup]

    @State private var showAddSheet = false

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if setups.isEmpty {
                    ContentUnavailableView(
                        "No Setups Yet",
                        systemImage: "backpack.fill",
                        description: Text("Add a camping setup to track cost per night.")
                    )
                } else {
                    List {
                        ForEach(setups) { setup in
                            SetupRowView(setup: setup)
                        }
                        .onDelete(perform: deleteSetups)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Setups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if !setups.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditSetupView()
            }
        }
    }

    private func deleteSetups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(setups[index])
        }
        try? modelContext.save()
    }
}

private struct SetupRowView: View {
    let setup: CampingSetup

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(setup.name)
                .font(.headline)

            HStack(spacing: 16) {
                Label(
                    Self.currencyFormatter.string(from: NSNumber(value: setup.cost)) ?? "$\(setup.cost)",
                    systemImage: "tag.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                let nights = setup.totalNights
                Label(
                    "\(nights) night\(nights == 1 ? "" : "s")",
                    systemImage: "moon.stars.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if setup.totalNights > 0 {
                let cpn = Self.currencyFormatter.string(from: NSNumber(value: setup.costPerNight)) ?? "$\(setup.costPerNight)"
                Text("\(cpn) / night")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            } else {
                Text("Log trips to calculate cost/night")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
