import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:window_size/window_size.dart';
import 'dart:io' show Platform;

// Import only for Windows specific WebView implementation
import 'package:webview_windows/webview_windows.dart' as windows_webview;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up window size for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('AI Tools Browser');
    setWindowMinSize(const Size(800, 600));
    setWindowMaxSize(Size.infinite);
  }

  runApp(const MyBrowserApp());
}

class MyBrowserApp extends StatelessWidget {
  const MyBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MultiWindowBrowser(),
    );
  }
}

class MultiWindowBrowser extends StatefulWidget {
  const MultiWindowBrowser({super.key});

  @override
  State<MultiWindowBrowser> createState() => _MultiWindowBrowserState();
}

class _MultiWindowBrowserState extends State<MultiWindowBrowser>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0; // <---- Fix: Track current page

  final List<BrowserWindow> _windows = [
    BrowserWindow(
      title: 'Window 1',
      tabs: [
        BrowserTab(title: 'ChatGPT', url: 'https://chat.openai.com'),
        BrowserTab(title: 'Claude', url: 'https://claude.ai'),
        BrowserTab(title: 'DeepSeek', url: 'https://deepseek.com'),
        BrowserTab(title: 'Perplexity', url: 'https://www.perplexity.ai'),
      ],
    ),
    BrowserWindow(
      title: 'Window 2',
      tabs: [
        BrowserTab(title: 'Bard', url: 'https://bard.google.com'),
        BrowserTab(title: 'Bing Chat', url: 'https://www.bing.com/chat'),
        BrowserTab(title: 'HuggingChat', url: 'https://huggingface.co/chat'),
        BrowserTab(title: 'ChatGPT', url: 'https://chat.openai.com'),
      ],
    ),
    BrowserWindow(
      title: 'Window 3',
      tabs: [
        BrowserTab(title: 'Anthropic', url: 'https://www.anthropic.com'),
        BrowserTab(title: 'Character AI', url: 'https://character.ai'),
        BrowserTab(title: 'Pi', url: 'https://pi.ai'),
        BrowserTab(title: 'Inflection', url: 'https://inflection.ai'),
      ],
    ),
    BrowserWindow(
      title: 'Window 4',
      tabs: [
        BrowserTab(title: 'Custom 1', url: 'https://example.com'),
        BrowserTab(title: 'Custom 2', url: 'https://example.com'),
        BrowserTab(title: 'Custom 3', url: 'https://example.com'),
        BrowserTab(title: 'Custom 4', url: 'https://example.com'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize tab controllers for each window
    for (var window in _windows) {
      window.tabController =
          TabController(length: window.tabs.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all tab controllers
    for (var window in _windows) {
      window.tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tools Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                final currentWindow = _windows[_currentPage];
                final currentTab =
                    currentWindow.tabs[currentWindow.tabController.index];
                if (Platform.isWindows) {
                  currentTab.windowsController?.reload();
                } else {
                  currentTab.controller?.reload();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              setState(() {
                final currentWindow = _windows[_currentPage];
                final currentTab =
                    currentWindow.tabs[currentWindow.tabController.index];
                if (Platform.isWindows) {
                  currentTab.windowsController?.loadUrl(currentTab.url);
                } else {
                  currentTab.controller?.loadUrl(
                    urlRequest: URLRequest(url: Uri.parse(currentTab.url)),
                  );
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final currentWindow = _windows[_currentPage];
              final currentTab =
                  currentWindow.tabs[currentWindow.tabController.index];

              switch (value) {
                case 'clearCookies':
                  await CookieManager.instance().deleteAllCookies();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Cookies cleared')),
                    );
                  }
                  break;
                case 'clearCache':
                  if (Platform.isWindows) {
                    // Windows WebView cache clearing is not supported directly
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cache clearing not supported on Windows')),
                      );
                    }
                  } else {
                    await currentTab.controller?.clearCache();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    }
                  }
                  break;
                case 'addTab':
                  _showAddTabDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clearCookies',
                child: Text('Clear Cookies'),
              ),
              const PopupMenuItem(
                value: 'clearCache',
                child: Text('Clear Cache'),
              ),
              const PopupMenuItem(
                value: 'addTab',
                child: Text('Add New Tab'),
              ),
            ],
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _windows.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildWindow(_windows[index]);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        height: 30,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              'Window: ${_windows[_currentPage].title}',
              style: const TextStyle(fontSize: 12),
            ),
            const Spacer(),
            Text(
              'Tab: ${_windows[_currentPage].tabs[_windows[_currentPage].tabController.index].title}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWindow(BrowserWindow window) {
    return Column(
      children: [
        TabBar(
          controller: window.tabController,
          isScrollable: true,
          tabs: window.tabs.map((tab) => Tab(text: tab.title)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: window.tabController,
            children: window.tabs.map((tab) => _buildWebView(tab)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWebView(BrowserTab tab) {
    if (Platform.isWindows) {
      return _buildWindowsWebView(tab);
    } else {
      return _buildCrossWebView(tab);
    }
  }

  Widget _buildWindowsWebView(BrowserTab tab) {
    // Create a container where we'll place our Windows WebView
    return FutureBuilder<void>(
      future: _prepareWindowsWebView(tab),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Return a container with specific size to host the WebView
          return Container(
            color: Colors.white,
            child: tab.windowsController != null
                ? windows_webview.Webview(tab.windowsController!)
                : const Center(child: Text('WebView not initialized')),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _prepareWindowsWebView(BrowserTab tab) async {
    if (tab.windowsController == null) {
      final controller = windows_webview.WebviewController();
      await controller.initialize();
      await controller.setBackgroundColor(Colors.white);

      // Set up listeners for loading states
      controller.url.listen((url) {
        if (mounted) {
          setState(() {
            tab.currentUrl = url;
          });
        }
      });

      // Load the URL after initialization
      await controller.loadUrl(tab.url);

      tab.windowsController = controller;
    }
  }

  Widget _buildCrossWebView(BrowserTab tab) {
    return InAppWebView(
      key: ValueKey('${tab.title}_${tab.width}_${tab.height}'),
      initialUrlRequest: URLRequest(url: Uri.parse(tab.url)),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
      ),
      onWebViewCreated: (controller) {
        tab.controller = controller;
      },
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            tab.isLoading = true;
            tab.currentUrl = url.toString();
          });
        }
      },
      onLoadStop: (controller, url) {
        if (mounted) {
          setState(() {
            tab.isLoading = false;
            tab.currentUrl = url.toString();
          });
        }
      },
      onProgressChanged: (controller, progress) {
        if (mounted) {
          setState(() {
            tab.progress = progress / 100;
          });
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("Console: ${consoleMessage.message}");
      },
    );
  }

  void _showAddTabDialog(BuildContext context) {
    final currentWindow = _windows[_currentPage];
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Add New Tab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tab Title'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                // Add http:// prefix if not present
                String url = urlController.text;
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }

                setState(() {
                  final newTab =
                      BrowserTab(title: titleController.text, url: url);
                  currentWindow.tabs.add(newTab);
                  currentWindow.tabController = TabController(
                    length: currentWindow.tabs.length,
                    vsync: this,
                  );
                });

                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class BrowserWindow {
  final String title;
  final List<BrowserTab> tabs;
  late TabController tabController;

  BrowserWindow({
    required this.title,
    required this.tabs,
  });
}

class BrowserTab {
  final String title;
  final String url;
  String currentUrl;
  InAppWebViewController? controller;
  windows_webview.WebviewController? windowsController;
  bool isLoading = true;
  double progress = 0.0;
  double width = 0;
  double height = 0;

  BrowserTab({
    required this.title,
    required this.url,
  }) : currentUrl = url;
}
