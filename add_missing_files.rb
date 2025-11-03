#!/usr/bin/env ruby

begin
  require 'xcodeproj'
rescue LoadError
  puts "❌ Il gem 'xcodeproj' non è installato!"
  puts ""
  puts "💡 SOLUZIONI ALTERNATIVE:"
  puts ""
  puts "1️⃣ Installa il gem (richiede sudo):"
  puts "   sudo gem install xcodeproj"
  puts ""
  puts "2️⃣ OPPURE aggiungi manualmente i file in Xcode:"
  puts "   - Apri GPT.xcodeproj"
  puts "   - Crea questi gruppi (tasto destro → New Group):"
  puts "     • Networking"
  puts "     • API"
  puts "     • Repositories"
  puts "     • Services"
  puts "   - Per ogni gruppo, tasto destro → 'Add Files to GPT...'"
  puts "   - Seleziona i file corrispondenti"
  puts ""
  puts "📁 FILE DA AGGIUNGERE:"
  puts ""
  puts "Networking/"
  puts "  • HTTPClient.swift"
  puts "  • SSEClient.swift"
  puts ""
  puts "API/"
  puts "  • Endpoints.swift"
  puts "  • DTOs.swift"
  puts "  • Decoders.swift"
  puts ""
  puts "Repositories/"
  puts "  • ConversationsRepository.swift"
  puts ""
  puts "Services/"
  puts "  • StreamingCenter.swift"
  puts "  • ChatService.swift"
  puts ""
  puts "Views/Shared/"
  puts "  • ErrorBanner.swift"
  puts ""
  exit 1
end

# Percorso del progetto Xcode
PROJECT_PATH = 'GPT.xcodeproj'
TARGET_NAME = 'GPT'

# File da aggiungere organizzati per gruppo
FILES_TO_ADD = {
  'Networking' => [
    'GPT/Networking/HTTPClient.swift',
    'GPT/Networking/SSEClient.swift'
  ],
  'API' => [
    'GPT/API/Endpoints.swift',
    'GPT/API/DTOs.swift',
    'GPT/API/Decoders.swift'
  ],
  'Repositories' => [
    'GPT/Repositories/ConversationsRepository.swift'
  ],
  'Services' => [
    'GPT/Services/StreamingCenter.swift',
    'GPT/Services/ChatService.swift'
  ],
  'Views/Shared' => [
    'GPT/Views/Shared/ErrorBanner.swift'
  ]
}

def add_files_to_project
  puts "==================================="
  puts "🤖 Aggiunta automatica file Xcode"
  puts "==================================="

  # Apri il progetto
  unless File.exist?(PROJECT_PATH)
    puts "❌ Progetto '#{PROJECT_PATH}' non trovato!"
    return
  end

  project = Xcodeproj::Project.open(PROJECT_PATH)
  target = project.targets.find { |t| t.name == TARGET_NAME }

  unless target
    puts "❌ Target '#{TARGET_NAME}' non trovato!"
    puts "Targets disponibili: #{project.targets.map(&:name).join(', ')}"
    return
  end

  puts "🔍 Controllo file mancanti..."
  added_count = 0
  skipped_count = 0

  FILES_TO_ADD.each do |group_name, files|
    puts "\n📁 Gruppo: #{group_name}"

    # Crea il gruppo se non esiste
    group = project.main_group.find_subpath(group_name, true)
    group.set_source_tree('<group>')

    files.each do |file_path|
      if File.exist?(file_path)
        # Verifica se il file è già nel progetto
        existing_file_ref = project.files.find { |f| f.real_path.to_s == File.expand_path(file_path) }

        if existing_file_ref
          puts "  ⚪ #{File.basename(file_path)} - già presente"
          skipped_count += 1
        else
          # Aggiungi il file
          file_ref = group.new_reference(file_path)
          target.add_file_references([file_ref])
          puts "  ✅ #{File.basename(file_path)} - aggiunto"
          added_count += 1
        end
      else
        puts "  ❌ #{File.basename(file_path)} - file non trovato!"
      end
    end
  end

  # Salva il progetto
  project.save

  puts "\n==================================="
  puts "📊 Riepilogo:"
  puts "  ✅ File aggiunti: #{added_count}"
  puts "  ⚪ File saltati: #{skipped_count}"
  puts "💾 Progetto salvato!"
  puts ""
  puts "🎉 Completato!"
  puts "Ora puoi aprire Xcode e fare build (⌘B)"
  puts "==================================="
end

# Esegui lo script
if __FILE__ == $0
  add_files_to_project
end
