import SwiftUI
import AVKit

struct ZPlayerView: View {
    let videoUrl: String
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { presentation.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    Spacer()
                    Text("مشاهدة الآن")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                    Image(systemName: "airplayvideo")
                        .foregroundColor(.white)
                }
                .padding()

                if let url = URL(string: videoUrl) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("عذراً، الرابط غير متوفر")
                            .foregroundColor(.white)
                    }
                }
                
                // Episode Selector for Series
                VStack(alignment: .leading) {
                    Text("الحلقات")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(1..<21) { i in
                                Text("\(i)")
                                    .frame(width: 45, height: 45)
                                    .background(i == 1 ? Color.red : Color.gray.opacity(0.2))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}
