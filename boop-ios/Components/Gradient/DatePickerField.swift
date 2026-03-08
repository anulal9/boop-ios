import SwiftUI

struct DatePickerField: View {
    let title: String
    let placeholder: String
    let info: String?
    @Binding var selectedDate: Date?

    @State private var showingPicker = false
    @State private var tempMonth: Int
    @State private var tempDay: Int
    @State private var tempYear: Int

    private let months = Calendar.current.monthSymbols
    private let days = Array(1...31)
    private let years: [Int]

    init(title: String, placeholder: String, info: String? = nil, selectedDate: Binding<Date?>) {
        self.title = title
        self.placeholder = placeholder
        self.info = info
        self._selectedDate = selectedDate

        // Generate years from 1900 to current year
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array(1900...currentYear).reversed()

        // Initialize temp values from selected date or defaults
        let date = selectedDate.wrappedValue ?? Date()
        let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
        _tempMonth = State(initialValue: (components.month ?? 1) - 1) // 0-indexed
        _tempDay = State(initialValue: (components.day ?? 1) - 1) // 0-indexed
        _tempYear = State(initialValue: years.firstIndex(of: components.year ?? currentYear) ?? 0)
    }

    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            showingPicker = true
        }) {
            Text(displayText)
                .foregroundStyle(displayText == placeholder ? Color.textPrimary.opacity(0.6) : Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(CornerRadius.lg)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.textPrimary.opacity(0.2), lineWidth: 1)
                }
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .sheet(isPresented: $showingPicker) {
            DatePickerSheet(
                title: title,
                info: info,
                months: months,
                days: days,
                years: years,
                selectedMonth: $tempMonth,
                selectedDay: $tempDay,
                selectedYear: $tempYear,
                onClear: clearDate,
                onDismiss: saveDate
            )
            .presentationDetents([.height(305)])
            .presentationDragIndicator(.visible)
        }
    }

    private var displayText: String {
        guard let date = selectedDate else {
            return placeholder
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func clearDate() {
        selectedDate = nil
        showingPicker = false
    }

    private func saveDate() {
        var components = DateComponents()
        components.month = tempMonth + 1
        components.day = tempDay + 1
        components.year = years[tempYear]

        if let date = Calendar.current.date(from: components) {
            selectedDate = date
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    let title: String
    let info: String?
    let months: [String]
    let days: [Int]
    let years: [Int]

    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    @Binding var selectedYear: Int

    let onClear: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var tempDate: Date

    init(title: String, info: String?, months: [String], days: [Int], years: [Int],
         selectedMonth: Binding<Int>, selectedDay: Binding<Int>, selectedYear: Binding<Int>,
         onClear: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.title = title
        self.info = info
        self.months = months
        self.days = days
        self.years = years
        self._selectedMonth = selectedMonth
        self._selectedDay = selectedDay
        self._selectedYear = selectedYear
        self.onClear = onClear
        self.onDismiss = onDismiss

        // Initialize tempDate from current selections
        var components = DateComponents()
        components.month = selectedMonth.wrappedValue + 1
        components.day = selectedDay.wrappedValue + 1
        components.year = years[selectedYear.wrappedValue]
        let date = Calendar.current.date(from: components) ?? Date()
        _tempDate = State(initialValue: date)
    }

    var body: some View {
        VStack() {
            Spacer()

            // Header with Clear button and title
            HStack {
                Button("Clear") {
                    onClear()
                }
                .foregroundColor(Color.textPrimary)
                .font(.system(size: 17))

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                // Invisible button for symmetry
                Button("Clear") {
                    onClear()
                }
                .opacity(0)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)

            // Native iOS Date Picker with wheel style
            DatePicker(
                "",
                selection: $tempDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: tempDate) { _, newDate in
                let components = Calendar.current.dateComponents([.month, .day, .year], from: newDate)
                selectedMonth = (components.month ?? 1) - 1
                selectedDay = (components.day ?? 1) - 1
                if let year = components.year, let yearIndex = years.firstIndex(of: year) {
                    selectedYear = yearIndex
                }
                onDismiss()
            }
            // Info text
            if let info {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textPrimary)

                    Text(info)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textPrimary)
                }
                .padding(.bottom, Spacing.xl)
            } else {
                Spacer().frame(height: Spacing.xl)
            }
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DatePickerField(
            title: "Set birthday",
            placeholder: "Add birthday",
            info: "Your birth year is kept private",
            selectedDate: .constant(nil)
        )

        DatePickerField(
            title: "Set event date",
            placeholder: "Select date",
            info: "Choose any date",
            selectedDate: .constant(Date())
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
