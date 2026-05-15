import SwiftUI

struct HomeView: View {
    @EnvironmentObject var scraperService: ScraperService
    @State private var selectedContent: ContentItem?
    @State private var showDetail = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 24) {
                if scraperService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                        .tint(.red)
                } else {
                    ForEach(scraperService.homeSections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(section.title)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                if let seeAllUrl = section.seeAllUrl {
                                    Button("المزيد »") {
                                        // Handle see all
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(section.items) { item in
                                        ContentRow(item: item)
                                            .onTapGesture {
                                                selectedContent = item
                                                showDetail = true
                                            }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showDetail, content: {
            if let content = selectedContent {
                ContentDetailView(content: content)
                    .environmentObject(scraperService)
            }
        })
        .task {
            await scraperService.loadHomePage()
        }
        .refreshable {
            await scraperService.loadHomePage()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ScraperService())
}