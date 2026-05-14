import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 10)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    if vm.isLoading {
                        ProgressView()
                            .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.results.isEmpty && !vm.query.isEmpty {
                        emptyState
                    } else if vm.results.isEmpty {
                        hintView
                    } else {
                        resultsGrid
                    }
                }
            }
            .navigationTitle("بحث")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.07), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(white: 0.5))
                .font(.system(size: 16))
            
            TextField("ابحث عن فيلم أو مسلسل...", text: $vm.query)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: vm.query) { _ in
                    vm.search()
                }
                .onSubmit {
                    vm.search()
                }
            
            if !vm.query.isEmpty {
                Button {
                    vm.query = ""
                    vm.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.4))
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Results
    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(vm.results) { item in
                    MediaCard(item: item, width: 120, height: 175)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(white: 0.3))
            Text("لا توجد نتائج لـ \"\(vm.query)\"")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }
    
    // MARK: - Hint
    private var hintView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "popcorn")
                .font(.system(size: 52))
                .foregroundColor(Color(white: 0.25))
            Text("ابحث عن أي فيلم أو مسلسل")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }
}
