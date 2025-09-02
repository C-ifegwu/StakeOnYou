import SwiftUI

struct CreateGoalView: View {
    @ObservedObject var viewModel: CreateGoalViewModel

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $viewModel.title)
                TextField("Description", text: $viewModel.description, axis: .vertical)
                    .lineLimit(3...8)
                DatePicker("Start", selection: $viewModel.startDate, displayedComponents: [.date])
                DatePicker("End", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: [.date])
                Picker("Category", selection: $viewModel.category) {
                    ForEach(["Fitness & Exercise","Learning & Education","Career & Professional","Health & Wellness","Finance & Money","Other"], id: \.self) { c in
                        Text(c).tag(c)
                    }
                }
            }
            Section(header: Text("Stake")) {
                Toggle("Enable Stake", isOn: $viewModel.enableStake)
                if viewModel.enableStake {
                    TextField("Amount (USD)", value: $viewModel.stakeAmount, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            Section {
                Button(action: { Task { await viewModel.submit() } }) {
                    HStack {
                        if viewModel.isSubmitting { ProgressView().scaleEffect(0.8) }
                        Text("Create Goal")
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isSubmitting)
                if let success = viewModel.successMessage { Text(success).foregroundColor(.green) }
                if let error = viewModel.errorMessage { Text(error).foregroundColor(.red) }
            }
        }
        .navigationTitle("Create Goal")
    }
}


