import SwiftUI

struct EpisodeListView: View {
    let seasons: [Season]
    let onEpisodeSelected: (Episode) -> Void
    @State private var selectedSeasonIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Season selector
            if seasons.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(seasons.enumerated()), id: \.offset) { index, season in
                            Button(action: { selectedSeasonIndex = index }) {
                                Text("الموسم \(season.seasonNumber)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedSeasonIndex == index ? Color.red : Color.gray.opacity(0.3))
                                    .cornerRadius(20)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            Text("الحلقات")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Episodes grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(seasons[selectedSeasonIndex].episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })) { episode in
                    Button(action: { onEpisodeSelected(episode) }) {
                        VStack {
                            Text("\(episode.episodeNumber)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                            Text("ح\(episode.episodeNumber)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}