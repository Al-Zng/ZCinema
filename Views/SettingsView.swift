import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultQuality") private var defaultQuality = "Auto"
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @State private var showDisclaimer = false
    
    let qualities = ["Auto", "1080p", "720p", "480p"]
    
    var body: some View {
        NavigationView {
            List {
                Section("تفضيلات المشاهدة") {
                    Picker("الجودة الافتراضية", selection: $defaultQuality) {
                        ForEach(qualities, id: \.self) { quality in
                            Text(quality).tag(quality)
                        }
                    }
                    
                    Toggle("تشغيل الحلقة التالية تلقائياً", isOn: $autoPlayNext)
                }
                
                Section("عن التطبيق") {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Button("سياسة الخصوصية") {
                        // Open privacy policy
                    }
                    
                    Button("حول ZCinema") {
                        showDisclaimer = true
                    }
                    .alert(isPresented: $showDisclaimer) {
                        Alert(
                            title: Text("حول ZCinema"),
                            message: Text("هذا التطبيق هو مجرد واجهة لمحتوى متاح على الإنترنت. نحن لا نستضيف أي محتوى ولا نتحمل مسؤولية حقوق الطبع والنشر."),
                            dismissButton: .default(Text("حسناً"))
                        )
                    }
                }
                
                Section("تواصل معنا") {
                    Link("تابعنا على تليجرام", destination: URL(string: "https://t.me/zcinema")!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("الإعدادات")
            .preferredColorScheme(.dark)
            .listStyle(InsetGroupedListStyle())
        }
    }
}