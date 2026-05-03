import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var interactive: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .font(.title2)
                    .onTapGesture {
                        guard interactive else { return }
                        rating = (rating == star) ? 0 : star
                    }
            }
        }
    }
}

struct StarRatingReadOnly: View {
    let rating: Int
    var maxRating: Int = 5

    var body: some View {
        StarRatingView(rating: .constant(rating), interactive: false)
    }
}
