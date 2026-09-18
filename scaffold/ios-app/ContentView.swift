import SwiftUI
import WebKit

// MARK: - 文件模型
struct ProtoFile: Codable, Identifiable {
    var id: String { path }
    let path: String
    let name: String
    let folder: String
}

// MARK: - 文件列表加载器
class ProtoFileLoader: ObservableObject {
    @Published var files: [ProtoFile] = []
    @Published var activeFile: ProtoFile? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    var host: String { ContentView.serverHost }
    var port: Int { ContentView.serverPort }

    func fetch() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "http://\(host):\(port)/api/list") else {
            errorMessage = "无效的服务器地址"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error {
                    self?.errorMessage = "连接失败: \(error.localizedDescription)"
                    return
                }
                guard let data else {
                    self?.errorMessage = "无数据"
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let filesArray = json["files"] as? [[String: Any]],
                       let activePath = json["active"] as? String {

                        let files = filesArray.compactMap { dict -> ProtoFile? in
                            guard let path = dict["path"] as? String,
                                  let name = dict["name"] as? String,
                                  let folder = dict["folder"] as? String
                            else { return nil }
                            return ProtoFile(path: path, name: name, folder: folder)
                        }
                        self?.files = files
                        // 自动选中 active 文件（最近一次生成的原型）
                        self?.activeFile = files.first { $0.path == activePath }
                    }
                } catch {
                    self?.errorMessage = "解析失败: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - WKWebView 封装
struct ProtoWebView: UIViewRepresentable {
    let filePath: String
    let host: String
    let port: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isTextInteractionEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.navigationDelegate = context.coordinator
        webView.scrollView.refreshControl = context.coordinator.refreshControl
        webView.isOpaque = false
        webView.backgroundColor = UIColor.systemBackground

        context.coordinator.webView = webView
        loadPage(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.path != "/\(filePath)" {
            loadPage(in: uiView)
        }
    }

    private func loadPage(in webView: WKWebView) {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        components.path = "/" + filePath
        if let url = components.url {
            webView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        let refreshControl = UIRefreshControl()

        override init() {
            super.init()
            refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        }

        @objc func refresh() { webView?.reload() }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            refreshControl.endRefreshing()
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            refreshControl.endRefreshing()
        }
    }
}

// MARK: - 主界面
struct ContentView: View {
    static let serverHost = "127.0.0.1"
    static let serverPort = 8080

    @StateObject private var loader = ProtoFileLoader()
    @State private var selectedFile: ProtoFile?
    @State private var showFilePicker = false
    @State private var refreshID = UUID()
    @State private var toolbarVisible = true
    @State private var hideTask: Task<Void, Never>? = nil

    private var currentFile: ProtoFile? {
        selectedFile ?? loader.activeFile ?? loader.files.first
    }

    private func showToolbar(thenAutoHide: Bool = true) {
        hideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            toolbarVisible = true
        }
        guard thenAutoHide else { return }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                toolbarVisible = false
            }
        }
    }

    var body: some View {
        ZStack {
            // 原型页面 — 始终全屏
            if let file = currentFile {
                ProtoWebView(filePath: file.path, host: Self.serverHost, port: Self.serverPort)
                    .id(refreshID)
                    .ignoresSafeArea()
            } else {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("没有找到原型页面")
                        .font(.headline)
                    Text("在工作区目录下创建 .html 文件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("并确保服务器已启动")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }

            // 工具栏区域 — 与页面同级，不拦截页面交互
            VStack {
                Spacer()
                if toolbarVisible {
                    // 完整工具栏
                    HStack(spacing: 12) {
                        Button {
                            showFilePicker = true
                            loader.fetch()
                            showToolbar(thenAutoHide: false)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                    .font(.system(size: 13))
                                Text(currentFile?.name ?? "选择页面")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }

                        Spacer()

                        Button {
                            refreshID = UUID()
                            showToolbar()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // 工具栏隐藏时：底部显示一条无形触控条，点击唤起工具栏
                    Color.clear
                        .frame(height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showToolbar()
                        }
                }
            }
        }
        // 文件选择器关闭后恢复自动隐藏
        .onChange(of: showFilePicker) { old, showing in
            if !showing {
                showToolbar()
            }
        }
        .onAppear {
            loader.fetch()
            showToolbar()
        }
        // 文件选择器
        .sheet(isPresented: $showFilePicker) {
            FilePickerView(
                files: loader.files,
                selectedFile: currentFile,
                isLoading: loader.isLoading,
                errorMessage: loader.errorMessage,
                onSelect: { file in
                    selectedFile = file
                    showFilePicker = false
                },
                onRefresh: { loader.fetch() }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - 文件选择器
struct FilePickerView: View {
    let files: [ProtoFile]
    let selectedFile: ProtoFile?
    let isLoading: Bool
    let errorMessage: String?
    let onSelect: (ProtoFile) -> Void
    let onRefresh: () -> Void

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("无法连接服务器")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("重试", action: onRefresh)
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if files.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("暂无原型页面")
                            .font(.headline)
                        Text("在工作区目录下创建 .html 文件后刷新")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("刷新", action: onRefresh)
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        let grouped = Dictionary(grouping: files) { $0.folder }
                        let sortedGroups = grouped.keys.sorted()

                        ForEach(sortedGroups, id: \.self) { folder in
                            Section(folder.isEmpty ? "根目录" : folder) {
                                ForEach(grouped[folder] ?? []) { file in
                                    Button {
                                        onSelect(file)
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.richtext")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(file.name)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                Text(file.path)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if file.path == selectedFile?.path {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("原型页面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { onRefresh() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        UIApplication.shared
                            .connectedScenes
                            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                            .first?
                            .rootViewController?
                            .dismiss(animated: true)
                    }
                }
            }
        }
    }
}
