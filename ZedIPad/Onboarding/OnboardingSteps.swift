import SwiftUI

// MARK: - Step 1: Welcome

struct OnboardingWelcomeStep: View {
    @State private var appear = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color(hex: "#89b4fa").opacity(0.15))
                    .frame(width: 120, height: 120)
                Text("</>")
                    .font(.system(size: 40, weight: .light, design: .monospaced))
                    .foregroundColor(Color(hex: "#89b4fa"))
            }
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)

            VStack(spacing: 8) {
                Text("Welcome to ZedIPad")
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#cdd6f4"))
                Text("A Zed-inspired code editor\nbuilt natively for iPad")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#6e738d"))
                    .multilineTextAlignment(.center)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            // Feature bullets
            VStack(alignment: .leading, spacing: 12) {
                OnboardingBullet(icon: "chevron.left.forwardslash.chevron.right", text: "Syntax highlighting for 21 languages")
                OnboardingBullet(icon: "terminal", text: "Built-in terminal with 24 shell commands")
                OnboardingBullet(icon: "network", text: "SSH to remote servers")
                OnboardingBullet(icon: "arrow.triangle.branch", text: "Git integration")
                OnboardingBullet(icon: "folder", text: "Real filesystem — browse your files")
            }
            .padding(.horizontal, 40)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }
}

// MARK: - Step 2: Editor

struct OnboardingEditorStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            OnboardingStepHeader(icon: "doc.text", title: "Powerful Code Editor")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#181b1f"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#313244"), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    OnboardingCodeLine(lineNo: "1", code: "import SwiftUI", color: "#cba6f7")
                    OnboardingCodeLine(lineNo: "2", code: "")
                    OnboardingCodeLine(lineNo: "3", code: "struct ContentView: View {", color: "#89dceb")
                    OnboardingCodeLine(lineNo: "4", code: "    @State private var text = \"\"", color: "#a6e3a1")
                    OnboardingCodeLine(lineNo: "5", code: "    var body: some View {", color: "#cba6f7")
                    OnboardingCodeLine(lineNo: "6", code: "        TextEditor(text: $text)", color: "#cdd6f4")
                    OnboardingCodeLine(lineNo: "7", code: "    }", color: "#cdd6f4")
                    OnboardingCodeLine(lineNo: "8", code: "}", color: "#cdd6f4")
                }
                .padding(12)
            }
            .frame(height: 200)
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                OnboardingBullet(icon: "paintbrush", text: "Syntax highlighting for 21 languages")
                OnboardingBullet(icon: "list.number", text: "Line numbers, minimap, breadcrumb")
                OnboardingBullet(icon: "magnifyingglass", text: "Find & replace with regex support")
                OnboardingBullet(icon: "rectangle.split.2x1", text: "Split editor view")
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Step 3: Terminal

struct OnboardingTerminalStep: View {
    @State private var typedText = ""
    private let fullCommand = "ls -la"
    private let output = """
    drwxr-xr-x  Sources/
    drwxr-xr-x  Tests/
    -rw-r--r--  Package.swift
    -rw-r--r--  README.md
    """

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            OnboardingStepHeader(icon: "terminal", title: "Built-in Terminal")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#181b1f"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#313244"), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text("ZedIPad Terminal — type 'help' for commands")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#89b4fa"))
                    Text("~ $ \(typedText)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#a6e3a1"))
                    if typedText == fullCommand {
                        Text(output)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#cdd6f4"))
                    }
                }
                .padding(12)
            }
            .frame(height: 160)
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                OnboardingBullet(icon: "keyboard", text: "24 built-in shell commands")
                OnboardingBullet(icon: "network", text: "SSH to remote servers")
                OnboardingBullet(icon: "arrow.triangle.branch", text: "Git commands built in")
                OnboardingBullet(icon: "doc", text: "Open files from terminal in editor")
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .onAppear { animateTyping() }
    }

    private func animateTyping() {
        typedText = ""
        for (i, char) in fullCommand.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12 + 0.5) {
                typedText.append(char)
            }
        }
    }
}

// MARK: - Step 4: Files & Git

struct OnboardingFilesStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            OnboardingStepHeader(icon: "folder", title: "Files & Git")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#171a1d"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#313244"), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    OnboardingTreeRow(indent: 0, icon: "folder.fill", name: "my-project", badge: nil, color: "#89b4fa")
                    OnboardingTreeRow(indent: 1, icon: "folder", name: "Sources", badge: "M", color: "#89b4fa")
                    OnboardingTreeRow(indent: 2, icon: "swift", name: "main.swift", badge: "M", color: "#F05138")
                    OnboardingTreeRow(indent: 2, icon: "doc", name: "editor.swift", badge: "A", color: "#a6e3a1")
                    OnboardingTreeRow(indent: 1, icon: "doc.text", name: "README.md", badge: nil, color: "#8BE9FD")
                    OnboardingTreeRow(indent: 1, icon: "curlybraces", name: "Package.swift", badge: nil, color: "#F7B731")
                }
                .padding(12)
            }
            .frame(height: 160)
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                OnboardingBullet(icon: "folder", text: "Browse real filesystem — Documents & iCloud")
                OnboardingBullet(icon: "plus", text: "Create, rename, delete files & folders")
                OnboardingBullet(icon: "arrow.triangle.branch", text: "Git status badges (M=modified, A=added)")
                OnboardingBullet(icon: "icloud", text: "iCloud Drive integration")
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Step 5: Ready

struct OnboardingReadyStep: View {
    @State private var confettiVisible = false

    var body: some View {
        ZStack {
            if confettiVisible {
                ConfettiView()
            }

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: "#a6e3a1").opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#a6e3a1"))
                }

                VStack(spacing: 8) {
                    Text("You're All Set!")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: "#cdd6f4"))
                    Text("ZedIPad is ready to use.\nStart by opening a file from the sidebar.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#6e738d"))
                        .multilineTextAlignment(.center)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiVisible = true
            }
        }
    }
}

struct ConfettiView: View {
    let colors: [Color] = [Color(hex: "#89b4fa"), Color(hex: "#a6e3a1"), Color(hex: "#cba6f7"),
                           Color(hex: "#fab387"), Color(hex: "#f9e2af"), Color(hex: "#89dceb")]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<60 {
                    let x = (sin(Double(i) * 1.7 + t * 2.1) + 1) / 2 * size.width
                    let y = (CGFloat(i) / 60 * size.height + t * 120).truncatingRemainder(dividingBy: size.height)
                    let color = colors[i % colors.count]
                    let rect = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.7)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Reusable Components

struct OnboardingStepHeader: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Color(hex: "#89b4fa"))
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "#cdd6f4"))
        }
    }
}

struct OnboardingBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#89b4fa"))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#cdd6f4"))
        }
    }
}

struct OnboardingCodeLine: View {
    let lineNo: String
    let code: String
    var color: String = "#cdd6f4"

    var body: some View {
        HStack(spacing: 12) {
            Text(lineNo)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "#45475a"))
                .frame(width: 16, alignment: .trailing)
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: color))
        }
    }
}

struct OnboardingTreeRow: View {
    let indent: Int
    let icon: String
    let name: String
    let badge: String?
    let color: String

    var body: some View {
        HStack(spacing: 6) {
            Spacer().frame(width: CGFloat(indent) * 16)
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: color))
            Text(name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "#cdd6f4"))
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(badge == "M" ? Color(hex: "#f9e2af") : Color(hex: "#a6e3a1"))
                    .frame(width: 14, height: 14)
                    .background(badge == "M" ? Color(hex: "#f9e2af").opacity(0.2) : Color(hex: "#a6e3a1").opacity(0.2))
                    .cornerRadius(3)
            }
        }
    }
}
