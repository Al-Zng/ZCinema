import SwiftUI

struct HomeView: View {
    @State private var items = [MediaContent]()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Brand Header
                        HStack {
                            Image(systemName: "play.rectangle.on.rectangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 24))
                            Text("ZCinema")
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "person.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        }
                        .padding(.horizontal)

                        // Hero Section Placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.red.opacity(0.6), .black], startPoint: .top, endPoint: .bottom))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("شاهد الآن")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("أحدث الأفلام والمسلسلات")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        Image(systemName: "play.fill")
                                            .padding()
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .foregroundColor(.black)
                                    }
                                    .padding()
                                }
                            )
                            .padding(.horizontal)

                        Text("المضاف حديثاً")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(0..<6) { _ in
                                MovieCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MovieCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 220)
                
                Text("HD")
                    .font(.system(size: 10, weight: .bold))
                    .padding(4)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(4)
                    .padding(8)
            }
            
            Text("اسم الفيلم هنا")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 10))
                Text("8.5")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}
