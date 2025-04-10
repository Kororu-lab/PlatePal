import SwiftUI

struct DebugView: View {
    @Binding var isPresented: Bool
    let recommendationData: [RestaurantScore]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(recommendationData) { restaurant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(restaurant.name)
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.2f", restaurant.score))
                                    .font(.headline)
                                    .foregroundColor(scoreColor(restaurant.score))
                            }
                            
                            HStack {
                                Text(restaurant.category)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(restaurant.distance))m")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            ScoreBarView(scores: restaurant.componentScores)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Text("점수 구성: 거리(D), 가격(P), 카테고리(C), 선호도(F), 랜덤(R)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .navigationTitle("추천 시스템 디버그")
            .navigationBarItems(trailing: Button("닫기") {
                isPresented = false
            })
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .blue
        } else if score >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ScoreBarView: View {
    let scores: ComponentScores
    
    var body: some View {
        HStack(spacing: 2) {
            ScoreSegmentView(value: scores.distance, label: "D", color: .blue)
            ScoreSegmentView(value: scores.price, label: "P", color: .green)
            ScoreSegmentView(value: scores.category, label: "C", color: .orange)
            ScoreSegmentView(value: scores.favorite, label: "F", color: .red)
            ScoreSegmentView(value: scores.random, label: "R", color: .purple)
        }
        .frame(height: 20)
    }
}

struct ScoreSegmentView: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.7))
                .frame(width: CGFloat(value * 50))
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// Model for debugging
struct RestaurantScore: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let distance: Double
    let score: Double
    let componentScores: ComponentScores
}

struct ComponentScores {
    let distance: Double
    let price: Double 
    let category: Double
    let favorite: Double
    let random: Double
}

// Sample data for preview
extension RestaurantScore {
    static var sampleData: [RestaurantScore] = [
        RestaurantScore(
            name: "맛있는 한식당", 
            category: "한식", 
            distance: 650, 
            score: 0.87,
            componentScores: ComponentScores(
                distance: 0.9, 
                price: 0.8, 
                category: 0.95, 
                favorite: 0.7, 
                random: 0.9
            )
        ),
        RestaurantScore(
            name: "중화요리", 
            category: "중식", 
            distance: 1200, 
            score: 0.72,
            componentScores: ComponentScores(
                distance: 0.6, 
                price: 0.7, 
                category: 0.8, 
                favorite: 0.8, 
                random: 0.7
            )
        ),
        RestaurantScore(
            name: "스시하우스", 
            category: "일식", 
            distance: 850, 
            score: 0.65,
            componentScores: ComponentScores(
                distance: 0.7, 
                price: 0.5, 
                category: 0.6, 
                favorite: 0.7, 
                random: 0.8
            )
        ),
        RestaurantScore(
            name: "이탈리안 레스토랑", 
            category: "양식", 
            distance: 1800, 
            score: 0.58,
            componentScores: ComponentScores(
                distance: 0.4, 
                price: 0.3, 
                category: 0.7, 
                favorite: 0.9, 
                random: 0.6
            )
        ),
        RestaurantScore(
            name: "치킨집", 
            category: "치킨", 
            distance: 450, 
            score: 0.42,
            componentScores: ComponentScores(
                distance: 0.9, 
                price: 0.6, 
                category: 0.4, 
                favorite: 0.0, 
                random: 0.2
            )
        )
    ]
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView(isPresented: .constant(true), recommendationData: RestaurantScore.sampleData)
    }
} 