//
//  ContentView.swift
//  BetterRest
//
//  Created by Jacob LeCoq on 2/21/21.
//

import Combine
import CoreML
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var wakeUp: Date = defaultWakeTime {
        didSet {
            calculateBedtime()
        }
    }

    @Published var sleepAmount: Double = 8.0 {
        didSet {
            calculateBedtime()
        }
    }

    @Published var coffeeAmount: Int = 1 {
        didSet {
            calculateBedtime()
        }
    }

    var bedTimeMessage = ""

    init() {
        calculateBedtime()
    }

    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0

        return Calendar.current.date(from: components) ?? Date()
    }

    private func calculateBedtime() {
        do {
            let model: SleepCalculator = try SleepCalculator(configuration: MLModelConfiguration())

            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60

            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))

            let sleepTime = wakeUp - prediction.actualSleep

            let formatter = DateFormatter()
            formatter.timeStyle = .short

            bedTimeMessage = formatter.string(from: sleepTime)
        } catch {
            print(error)
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Text("When do you want to wake up?")
                        .font(.headline)

                    DatePicker("Please enter a time", selection: $viewModel.wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(WheelDatePickerStyle())

                    Section {
                        Picker("Desired amount of sleep", selection: $viewModel.sleepAmount) {
                            ForEach(Array(stride(from: 4.0, through: 12, by: 0.25)), id: \.self) { index in
                                Text("\(index, specifier: "%g") hours")
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())

                        Picker("Daily coffee intake", selection: $viewModel.coffeeAmount) {
                            ForEach(Array(stride(from: 1, through: 20, by: 1)), id: \.self) { coffeeAmount in
                                if coffeeAmount == 1 {
                                    Text("1 cup")
                                } else {
                                    Text("\(coffeeAmount) cups")
                                }
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                }
                .navigationBarTitle("BetterRest")

                Spacer()

                Text("Go to bed at: \(viewModel.bedTimeMessage)")
                    .font(.title2).bold()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
