import SwiftUI

struct DatePickerField: View {
    let title: String
    let placeholder: String
    let info: String?
    let showTimePicker: Bool
    @Binding var selectedDate: Date?

    @State private var showingPicker = false
    @State private var tempMonth: Int
    @State private var tempDay: Int
    @State private var tempYear: Int

    private let months = Calendar.current.monthSymbols
    private let days = Array(1...31)
    private let years: [Int]

    init(title: String, placeholder: String, info: String? = nil, showTimePicker: Bool = false, selectedDate: Binding<Date?>) {
        self.title = title
        self.placeholder = placeholder
        self.info = info
        self.showTimePicker = showTimePicker
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
                showTimePicker: showTimePicker,
                months: months,
                days: days,
                years: years,
                selectedMonth: $tempMonth,
                selectedDay: $tempDay,
                selectedYear: $tempYear,
                onClear: clearDate,
                onSave: saveDate
            )
            .presentationDetents([.height(305)])
            .presentationDragIndicator(.visible)
        }
    }

    private var displayText: String {
        guard let date = selectedDate else { return placeholder }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = showTimePicker ? .short : .none
        return formatter.string(from: date)
    }

    private func clearDate() {
        selectedDate = nil
        showingPicker = false
    }

    private func saveDate(_ pickedDate: Date) {
        selectedDate = pickedDate
        showingPicker = false
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    let title: String
    let info: String?
    let showTimePicker: Bool
    let months: [String]
    let days: [Int]
    let years: [Int]

    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    @Binding var selectedYear: Int

    let onClear: () -> Void
    let onSave: (Date) -> Void

    @State private var tempDate: Date
    @State private var tempTime: Date
    @State private var showingTime: Bool = false

    init(title: String, info: String?, showTimePicker: Bool,
         months: [String], days: [Int], years: [Int],
         selectedMonth: Binding<Int>, selectedDay: Binding<Int>, selectedYear: Binding<Int>,
         onClear: @escaping () -> Void, onSave: @escaping (Date) -> Void) {
        self.title = title
        self.info = info
        self.showTimePicker = showTimePicker
        self.months = months
        self.days = days
        self.years = years
        self._selectedMonth = selectedMonth
        self._selectedDay = selectedDay
        self._selectedYear = selectedYear
        self.onClear = onClear
        self.onSave = onSave

        let now = Date()
        var components = DateComponents()
        components.month = selectedMonth.wrappedValue + 1
        components.day = selectedDay.wrappedValue + 1
        components.year = years[selectedYear.wrappedValue]
        _tempDate = State(initialValue: Calendar.current.date(from: components) ?? now)
        _tempTime = State(initialValue: now)
    }

    private func combinedDate() -> Date {
        let dateParts = Calendar.current.dateComponents([.year, .month, .day], from: tempDate)
        let timeParts = Calendar.current.dateComponents([.hour, .minute], from: tempTime)
        var combined = DateComponents()
        combined.year = dateParts.year
        combined.month = dateParts.month
        combined.day = dateParts.day
        combined.hour = timeParts.hour
        combined.minute = timeParts.minute
        return Calendar.current.date(from: combined) ?? tempDate
    }

    var body: some View {
        VStack {
            Spacer()

            // Header
            HStack {
                if showTimePicker && showingTime {
                    Button("Back") {
                        withAnimation { showingTime = false }
                    }
                    .foregroundColor(Color.textPrimary)
                    .font(.system(size: 17))
                } else {
                    Button("Clear") {
                        onClear()
                    }
                    .foregroundColor(Color.textPrimary)
                    .font(.system(size: 17))
                }

                Spacer()

                Text(showTimePicker && showingTime ? "Time" : title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                if showTimePicker && !showingTime {
                    Button("Next") {
                        withAnimation { showingTime = true }
                    }
                    .foregroundColor(Color.accentPrimary)
                    .font(.system(size: 17, weight: .semibold))
                } else {
                    Button("Done") {
                        onSave(combinedDate())
                    }
                    .foregroundColor(Color.accentPrimary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)

            if showTimePicker && showingTime {
                // Step 2: Time wheel
                DatePicker("", selection: $tempTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            } else {
                // Step 1: Date wheel
                DatePicker("", selection: $tempDate, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: tempDate) { _, newDate in
                        let components = Calendar.current.dateComponents([.month, .day, .year], from: newDate)
                        selectedMonth = (components.month ?? 1) - 1
                        selectedDay = (components.day ?? 1) - 1
                        if let year = components.year, let yearIndex = years.firstIndex(of: year) {
                            selectedYear = yearIndex
                        }
                    }
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
            title: "Date & Time",
            placeholder: "When did this happen?",
            showTimePicker: true,
            selectedDate: .constant(Date())
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
