//
//  EditBookView.swift
//  MyBookShelf
//

import SwiftUI
import CoreData
import UIKit

private let genres = ["Fiction", "Non-fiction", "Science Fiction", "Fantasy", "Mystery", "Thriller", "Romance", "Poetry", "Biography", "History", "Science", "Psychology", "Business", "Self-help", "Children's", "Comics", "Horror", "Adventure", "Philosophy", "Other"]

struct EditBookView: View {
    let book: Book
    let onDismiss: () -> Void
    @State private var title: String
    @State private var author: String
    @State private var totalPages: Int
    @State private var genre: String
    @State private var customGenre: String
    @State private var publishYear: String
    @State private var isbn: String
    @State private var notes: String
    @State private var coverImage: UIImage?
    @State private var showImageOptions = false
    @State private var showImagePicker = false
    @State private var useCamera = false

    init(book: Book, onDismiss: @escaping () -> Void) {
        self.book = book
        self.onDismiss = onDismiss
        _title = State(initialValue: book.title ?? "")
        _author = State(initialValue: book.author ?? "")
        _totalPages = State(initialValue: Int(book.totalPages))
        _genre = State(initialValue: book.genre ?? "Fiction")
        _customGenre = State(initialValue: genres.contains(book.genre ?? "") ? "" : (book.genre ?? ""))
        _publishYear = State(initialValue: book.publishYear > 0 ? "\(book.publishYear)" : "")
        _isbn = State(initialValue: book.isbn ?? "")
        _notes = State(initialValue: book.notes ?? "")
        if let path = book.localCoverImagePath, let img = CacheService.shared.getImage(path: path) {
            _coverImage = State(initialValue: img)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showImageOptions = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.backgroundTertiary)
                                .aspectRatio(2/3, contentMode: .fit)
                            if let img = coverImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                    Text("Add cover")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Pages", value: $totalPages, format: .number)
                        .keyboardType(.numberPad)
                    Picker("Genre", selection: $genre) {
                        ForEach(genres, id: \.self) { Text($0).tag($0) }
                    }
                    if genre == "Other" {
                        TextField("Genre name", text: $customGenre)
                    }
                    TextField("Year", text: $publishYear)
                        .keyboardType(.numberPad)
                    TextField("ISBN", text: $isbn)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Edit book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Cover", isPresented: $showImageOptions) {
                Button("Camera") {
                    useCamera = true
                    showImagePicker = true
                }
                Button("Photo library") {
                    useCamera = false
                    showImagePicker = true
                }
                if coverImage != nil {
                    Button("Remove", role: .destructive) {
                        coverImage = nil
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose source")
            }
            .sheet(isPresented: $showImagePicker) {
                if useCamera {
                    ImagePicker(sourceType: .camera, onPick: {
                        coverImage = $0.mb_croppedToBookCoverAspect()
                        showImagePicker = false
                    }, onCancel: { showImagePicker = false })
                } else {
                    PHPickerView(onPick: {
                        coverImage = $0.mb_croppedToBookCoverAspect()
                        showImagePicker = false
                    }, onCancel: { showImagePicker = false })
                }
            }
        }
    }

    private func save() {
        book.title = title
        book.author = author
        book.totalPages = Int32(max(0, totalPages))
        book.genre = genre == "Other" ? customGenre : genre
        book.publishYear = Int32(publishYear) ?? 0
        book.isbn = isbn.isEmpty ? nil : isbn
        book.notes = notes
        if let img = coverImage, let id = book.id {
            if let path = CacheService.shared.saveCover(img, bookId: id) {
                book.localCoverImagePath = path
            }
        } else if coverImage == nil {
            book.localCoverImagePath = nil
        }
        try? PersistenceController.shared.container.viewContext.save()
        HapticsService.shared.success()
        onDismiss()
    }
}
