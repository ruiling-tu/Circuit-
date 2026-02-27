import Foundation

struct FeelingStateOption: Identifiable, Hashable {
    let id: String
    let title: String
    let distortions: [DistortionOption]
    let physioMode: PhysioMode
}

struct DistortionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let reframes: [String]
}

enum PhysioMode: String, CaseIterable {
    case breathing46
    case physiologicalSigh
    case grounding54321
    case postureLift
}

enum ResetContent {
    static let states: [FeelingStateOption] = [
        FeelingStateOption(
            id: "overwhelmed",
            title: "Overwhelmed",
            distortions: [
                DistortionOption(
                    id: "urgent",
                    title: "Everything is urgent",
                    reframes: [
                        "What actually breaks if this waits?",
                        "Which one thing matters most right now?",
                        "If I did only one piece, what would I choose?"
                    ]
                ),
                DistortionOption(
                    id: "alone",
                    title: "I must handle this alone",
                    reframes: [
                        "Who could help with a small piece?",
                        "What would I ask for if it were easy?",
                        "What is one delegation I can try?"
                    ]
                ),
                DistortionOption(
                    id: "failure",
                    title: "If I don’t fix this now, it fails",
                    reframes: [
                        "What’s the actual deadline?",
                        "What’s the smallest safe action?",
                        "If I delay, what’s the real impact?"
                    ]
                )
            ],
            physioMode: .breathing46
        ),
        FeelingStateOption(
            id: "anxious",
            title: "Anxious",
            distortions: [
                DistortionOption(
                    id: "catastrophizing",
                    title: "Catastrophizing",
                    reframes: [
                        "What is the most likely outcome?",
                        "What evidence do I actually have?",
                        "If it did go wrong, what would I do next?"
                    ]
                ),
                DistortionOption(
                    id: "mindReading",
                    title: "Mind reading",
                    reframes: [
                        "What do I actually know for sure?",
                        "Is there another possible explanation?",
                        "What would I tell a friend here?"
                    ]
                ),
                DistortionOption(
                    id: "fortuneTelling",
                    title: "Fortune telling",
                    reframes: [
                        "What outcomes are still possible?",
                        "What’s in my control today?",
                        "What would a calmer bet look like?"
                    ]
                ),
                DistortionOption(
                    id: "allOrNothing",
                    title: "All-or-nothing thinking",
                    reframes: [
                        "What’s a 10% improvement?",
                        "Where is the middle ground?",
                        "What’s one thing that is working?"
                    ]
                )
            ],
            physioMode: .breathing46
        ),
        FeelingStateOption(
            id: "irritated",
            title: "Irritated",
            distortions: [
                DistortionOption(
                    id: "should",
                    title: "This shouldn’t be happening",
                    reframes: [
                        "What’s frustrating about this, specifically?",
                        "What’s one thing I can accept for now?",
                        "What would help me lower the heat 10%?"
                    ]
                ),
                DistortionOption(
                    id: "personalized",
                    title: "They’re doing this to me",
                    reframes: [
                        "What else might be going on?",
                        "What part is mine to own?",
                        "What’s the simplest boundary?"
                    ]
                ),
                DistortionOption(
                    id: "labeling",
                    title: "Labeling",
                    reframes: [
                        "What’s the specific behavior I dislike?",
                        "How would I describe this neutrally?",
                        "What’s a fairer description?"
                    ]
                )
            ],
            physioMode: .physiologicalSigh
        ),
        FeelingStateOption(
            id: "scattered",
            title: "Mentally Scattered",
            distortions: [
                DistortionOption(
                    id: "tooMuch",
                    title: "There’s too much at once",
                    reframes: [
                        "What can wait 30 minutes?",
                        "What’s the smallest visible next step?",
                        "If I did one thing, which one?"
                    ]
                ),
                DistortionOption(
                    id: "noFocus",
                    title: "I can’t focus at all",
                    reframes: [
                        "When did I last focus even a little?",
                        "What environment tweak would help?",
                        "What’s a 5-minute focus task?"
                    ]
                ),
                DistortionOption(
                    id: "disorganized",
                    title: "I’m disorganized",
                    reframes: [
                        "What’s one simple structure I can set?",
                        "What would a 3-item list look like?",
                        "What can I remove?"
                    ]
                )
            ],
            physioMode: .grounding54321
        ),
        FeelingStateOption(
            id: "low",
            title: "Low / Discouraged",
            distortions: [
                DistortionOption(
                    id: "hopeless",
                    title: "Nothing I do matters",
                    reframes: [
                        "What’s one small thing I can influence?",
                        "What has helped me before?",
                        "What would I try if I had 5% more energy?"
                    ]
                ),
                DistortionOption(
                    id: "comparison",
                    title: "Everyone is ahead of me",
                    reframes: [
                        "What’s my actual path right now?",
                        "What’s one win I can name?",
                        "What would progress look like today?"
                    ]
                ),
                DistortionOption(
                    id: "permanent",
                    title: "This is permanent",
                    reframes: [
                        "When has this shifted before?",
                        "What might change in a week?",
                        "What’s one thing that is temporary?"
                    ]
                )
            ],
            physioMode: .postureLift
        ),
        FeelingStateOption(
            id: "pressure",
            title: "Performance Pressure",
            distortions: [
                DistortionOption(
                    id: "mustBePerfect",
                    title: "I must be perfect",
                    reframes: [
                        "What’s a solid B+ version?",
                        "What would I accept from someone else?",
                        "What does ‘good enough’ look like?"
                    ]
                ),
                DistortionOption(
                    id: "spotlight",
                    title: "Everyone is judging me",
                    reframes: [
                        "How much are others really tracking this?",
                        "What’s one supportive person’s view?",
                        "What would I notice if roles reversed?"
                    ]
                ),
                DistortionOption(
                    id: "allOnMe",
                    title: "It all rides on this",
                    reframes: [
                        "What’s one thing that would still be okay?",
                        "What’s the next step, not the whole outcome?",
                        "What’s within my control right now?"
                    ]
                )
            ],
            physioMode: .breathing46
        )
    ]

    static func state(for id: String) -> FeelingStateOption? {
        states.first { $0.id == id }
    }
}
