import SwiftUI

struct DatePickerField: View {
    let title: String
    let placeholder: String
    let info: String
    @Binding var selectedDate: Date?

    @State private var showingPicker = false
    @State private var tempMonth: Int
    @State private var tempDay: Int
    @State private var tempYear: Int

    private let months = Calendar.current.monthSymbols
    private let days = Array(1...31)
    private let years: [Int]

    // Text field specific gradient styling
    private let gradientColors: [Color] = [
        .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6),
        .pink.opacity(0.6), .indigo.opacity(0.7), .teal.opacity(0.6),
        .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6)
    ]
    private let gradientAnimationStyle: AnimatedMeshGradient.AnimationStyle = .verticalWave
    private let gradientDuration: Double = 3.0

    init(title: String, placeholder: String, info: String, selectedDate: Binding<Date?>) {
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
        Button(action: { showingPicker = true }) {
            ZStack(alignment: .center) {
                // Background with gradient or inactive color
                RoundedRectangle(cornerRadius: 22)
                    .fill(showingPicker ? Color.clear : Color.formBackgroundInactive)
                    .frame(height: 44)

                if showingPicker {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.clear)
                        .frame(height: 44)
                        .background(
                            AnimatedMeshGradient(
                                colors: gradientColors,
                                animationStyle: gradientAnimationStyle,
                                duration: gradientDuration
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        )
                }

                // Display text
                Text(displayText)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
            }
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
    let info: String
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

    init(title: String, info: String, months: [String], days: [Int], years: [Int],
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
                .foregroundColor(.white)
                .font(.system(size: 17))

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Invisible button for symmetry
                Button("Clear") {
                    onClear()
                }
                .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Native iOS Date Picker with wheel style
            DatePicker(
                "",
                selection: $tempDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
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
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Text(info)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
        }
        .background(Color.backgroundPrimary)
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
