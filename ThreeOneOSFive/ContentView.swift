                VStack(spacing: 22) {
                    HStack {
                        Spacer()
                        Button { showSettingsInfo = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(blue)
                                .padding(10)
                                .background(paleBlue, in: Circle())
                        }
                        .accessibilityLabel("Settings")
                    }
                    VStack(spacing: 5) {
                        Text("MISBAH PENAL")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(blue)
                        Text("Developer Shafay")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(blue.opacity(0.78))
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Key Authorization", systemImage: "key.horizontal")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(blue)
                        HStack(spacing: 10) {
                            TextField("Enter or paste your key", text: $keyText)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 0.08, green: 0.22, blue: 0.38))
                                .accessibilityLabel("License key")
                            Button {
                                if let pasted = UIPasteboard.general.string { keyText = pasted.trimmingCharacters(in: .whitespacesAndNewlines) }
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 12).padding(.vertical, 10)
                                    .background(paleBlue, in: RoundedRectangle(cornerRadius: 11))
                                    .foregroundStyle(blue)
                            }
                        }
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(blue.opacity(0.25), lineWidth: 1))

                        Button {
                            Task { await license.activate(key: keyText) }
                        } label: {
                            HStack(spacing: 9) {
                                if license.isVerifying { ProgressView().tint(.white) }
                                Text(license.isVerifying ? "Verifying..." : "Activate Key")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(license.isVerifying || keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if let message = license.message {
                            Text(message).font(.footnote.weight(.medium)).foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(blue.opacity(0.13), lineWidth: 1))
                    .shadow(color: blue.opacity(0.06), radius: 15, y: 6)

                    VStack(spacing: 12) {
                        Text("Our Official Channel")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(blue)
                        Link(destination: whatsappGroup) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.circle.fill").font(.system(size: 27)).foregroundStyle(Color(red: 0.10, green: 0.65, blue: 0.38))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Join our WhatsApp group").font(.system(size: 15, weight: .semibold)).foregroundStyle(blue)
                                    Text("Official updates and announcements").font(.system(size: 12)).foregroundStyle(blue.opacity(0.65))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundStyle(blue)
                            }
                            .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(blue.opacity(0.16), lineWidth: 1))
                        }
                        Link(destination: whatsappContact) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.circle.fill").font(.system(size: 27)).foregroundStyle(Color(red: 0.10, green: 0.65, blue: 0.38))
                                Text("+92 300 9353079").font(.system(size: 16, weight: .bold)).foregroundStyle(blue)
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundStyle(blue)
                            }
                            .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(blue.opacity(0.16), lineWidth: 1))
                        }
                    }
                    Text("MISBAH PENAL  •  Secure License Access")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(blue.opacity(0.55))
                        .padding(.top, 2)
                }
                .padding(20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.light)
        .alert("Settings", isPresented: $showSettingsInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("MISBAH PENAL • Developer Shafay")
        }
    }
}
