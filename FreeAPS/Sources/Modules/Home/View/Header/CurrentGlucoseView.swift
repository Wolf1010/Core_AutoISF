import CoreMedia
import SwiftUI

struct CurrentGlucoseView: View {
    @Binding var recentGlucose: BloodGlucose?
    @Binding var delta: Int?
    @Binding var units: GlucoseUnits
    @Binding var eventualBG: Int?
    @Binding var currentISF: Decimal?
    @Binding var alarm: GlucoseAlarm?
    @Binding var lowGlucose: Decimal
    @Binding var highGlucose: Decimal

    private var glucoseFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        if units == .mmolL {
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
        }
        formatter.roundingMode = .halfUp
        return formatter
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private var deltaFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "  +"
        formatter.negativePrefix = "  -"
        return formatter
    }

    private var timaAgoFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.negativePrefix = ""
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var minutesAgo: Int {
        let lastGlucoseDateString = recentGlucose.map { dateFormatter.string(from: $0.dateString) } ?? "--"
        let glucoseDate = Date(lastGlucoseDateString) ?? Date()
        let now = Date()
        let diff = Int(glucoseDate.timeIntervalSince1970 - now.timeIntervalSince1970)
        let hoursDiff = diff / 3600
        var minutesDiff = (diff - hoursDiff * 3600) / 60
        minutesDiff.negate() // Remove "-" sign
        return minutesDiff
    }

    func colorOfMinutesAgo(_ minutes: Int) -> Color {
        switch minutes {
        case 0 ... 5:
            return .loopGreen
        case 6 ... 9:
            return .loopYellow
        default:
            return .loopRed
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 7) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(
                    recentGlucose?.glucose
                        .map {
                            glucoseFormatter
                                .string(from: Double(units == .mmolL ? $0.asMmolL : Decimal($0)) as NSNumber)! }
                        ?? "--"
                )
                .font(.system(size: 32, weight: .bold))
                .fixedSize()
                // .foregroundColor(colorOfGlucose)
                .foregroundColor(alarm == nil ? colorOfGlucose : .loopRed)
                image.padding(.bottom, 2)

                if let eventualBG = eventualBG {
                    if units == .mmolL {
                        Text(
                            glucoseFormatter
                                .string(from: Decimal(eventualBG).asMmolL as NSNumber)!
                        )
                        .font(.system(size: 18, weight: .regular)).foregroundColor(.secondary).fixedSize()

                    } else {
                        Text("\(eventualBG)").font(.system(size: 18, weight: .regular)).foregroundColor(.secondary)
                            .fixedSize()
                    }
                }
                // Spacer()
            } // .padding(.leading, 0)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                // Spacer()
                let minutes = (recentGlucose?.dateString.timeIntervalSinceNow ?? 0) / 60
                let text = timaAgoFormatter.string(for: Double(minutes)) ?? ""
                Text(
                    text == "0" ? "< 1 " + NSLocalizedString("m", comment: "Short form for minutes") : (
                        text + " " +
                            NSLocalizedString("m", comment: "Short form for minutes")
                    )
                )
                .font(.system(size: 12, weight: .bold)).foregroundColor(colorOfMinutesAgo(minutesAgo))
                .fixedSize()
                Text(
                    delta
                        .map { deltaFormatter.string(from: Double(units == .mmolL ? $0.asMmolL : Decimal($0)) as NSNumber)!
                        } ??
                        "--"
                )
                .font(.system(size: 12, weight: .bold))
                .fixedSize()
                // Spacer()
                Text(
                    NSLocalizedString("ISF", comment: "current ISF") + ":"
                )
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .padding(.leading, 6)
                .fixedSize()
                Text(
                    numberFormatter.string(from: (currentISF ?? 0) as NSNumber) ?? "0"
                )
                .font(.system(size: 12, weight: .bold))
                .fixedSize()
                // Spacer()
            }
        }
    }

    var image: Image {
        guard let direction = recentGlucose?.direction else {
            return Image(systemName: "arrow.left.and.right")
        }

        switch direction {
        case .doubleUp,
             .singleUp,
             .tripleUp:
            return Image(systemName: "arrow.up")
        case .fortyFiveUp:
            return Image(systemName: "arrow.up.right")
        case .flat:
            return Image(systemName: "arrow.forward")
        case .fortyFiveDown:
            return Image(systemName: "arrow.down.forward")
        case .doubleDown,
             .singleDown,
             .tripleDown:
            return Image(systemName: "arrow.down")

        case .none,
             .notComputable,
             .rateOutOfRange:
            return Image(systemName: "arrow.left.and.right")
        }
    }

    var colorOfGlucose: Color {
        let whichGlucose = recentGlucose?.glucose ?? 0
        guard lowGlucose < highGlucose else { return .loopYellow }

        if highGlucose > 141 && lowGlucose > 55 && lowGlucose < 141               f {
            switch whichGlucose {
            case 55 ..< Int(lowGlucose):
                return .loopOrange
            case Int(lowGlucose) ..< 141:
                return .loopGreen
            case 141 ..< Int(highGlucose):
                return .loopYellow
            default:
                return .loopRed
            }
        } else {
            switch whichGlucose {
            case 0 ..< Int(lowGlucose):
                return .loopRed
            case Int(lowGlucose) ..< Int(highGlucose):
                return .loopGreen
            case Int(highGlucose)...:
                return .loopOrange
            default:
                return .loopRed
            }
        }
    }
}
