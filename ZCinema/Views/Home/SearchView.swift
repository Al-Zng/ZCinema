import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    private let columns = [GridItem(.adaptive(minimum: 108, maximum: 130), spacing: 10)]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                    Divider().background(Color(white: 0.18))

                    Group {
                        if vm.isLoading {
                            loadingGrid
                        } else if vm.query.isEmpty {
                            hintView
                        } else if vm.results.isEmpty {
                            emptyView
                        } else {
                            resultsGrid
                        }
                    }
                }
            }
            .navigationTitle("بحث")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.08), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }

    // ─── Search Bar ───────────────────────────────────────────────
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(white: 0.45))
                .font(.system(size: 15))

            TextField("ابحث عن فيلم أو مسلسل...", text: $vm.query)
                .foregroundColor(.white)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !vm.query.isEmpty {
                Button {
                    vm.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(11)
        .background(Color(white: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    // ─── Results ──────────────────────────────────────────────────
    private var resultsGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(vm.results) { item in
                    MediaCard(item: item)
                }
            }
            .padding(14)
        }
    }

    // ─── Loading ──────────────────────────────────────────────────
    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<12, id: \.self) { _ in SkeletonCard() }
            }
            .padding(14)
        }
    }

    // ─── Hint ─────────────────────────────────────────────────────
    private var hintView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "popcorn")
                .font(.system(size: 54))
                .foregroundColor(Color(white: 0.22))
            Text("ابحث عن أي فيلم أو مسلسل")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(white: 0.45))
            Spacer()
        }
    }

    // ─── Empty ────────────────────────────────────────────────────
    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(white: 0.25))
            Text("لا توجد نتائج لـ «\(vm.query)»")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(white: 0.45))
            Spacer()
        }
    }
}
