require 'fileutils'
require 'socket'

module Nightingale
  class CLI
    def self.new_project(name)
      puts "Creating new Nightingale project: #{name}..."
      FileUtils.mkdir_p(name)

      # Copy frontend template
      # In a real gem, this would be properly located.
      # For this repo, we assume we are running from the root.
      gem_root = File.expand_path('../../..', __FILE__)
      frontend_template = File.join(gem_root, 'frontend')

      if File.directory?(frontend_template)
        puts "Copying frontend template..."
        FileUtils.cp_r(frontend_template, File.join(name, 'frontend'))

        # Clean up node_modules and other artifacts from the template copy
        FileUtils.rm_rf(File.join(name, 'frontend', 'node_modules'))
        FileUtils.rm_rf(File.join(name, 'frontend', 'dist'))
        FileUtils.rm_rf(File.join(name, 'frontend', '.git'))

        # Create a basic app.rb
        puts "Creating sample app.rb..."
        File.write(File.join(name, 'app.rb'), <<~RUBY)
          require 'nightingale'

          title "My Nightingale App"
          markdown "Welcome to your new app!"

          if button "Click me"
            markdown "You clicked the button!"
          end
        RUBY

        # Create Gemfile
        puts "Creating Gemfile..."
        File.write(File.join(name, 'Gemfile'), <<~RUBY)
          source 'https://rubygems.org'
          gem 'nightingale', path: '#{gem_root}' # Local path for now
        RUBY

        puts "Installing frontend dependencies..."
        Dir.chdir(File.join(name, 'frontend')) do
          system("npm install")

          puts "Initializing Shadcn UI components..."
          # We assume components.json and tailwind.config.js are already in the template
          # So we just need to add the components
          # Note: 'shadcn add --all' might require interaction or confirmation, adding --yes or similar if available
          # Actually, shadcn add doesn't have a --yes flag usually, but we can try piping yes?
          # Or just installing specific components we use.
          # For now, let's install the ones we use in the template if any, or just let the user do it?
          # The user request said: "when user initialize the app will install them automatically"
          # Let's try to install button, slider, etc.

          # But wait, we haven't actually implemented the Shadcn components in our App.tsx yet.
          # We are still using HTML buttons.
          # We should update App.tsx to use Shadcn components first?
          # Or we install them now and the user can use them.

          # Let's install common components
          components = %w[button slider card input label table separator]
          puts "Installing components: #{components.join(', ')}..."
          system("npx shadcn@latest add #{components.join(' ')} --yes --overwrite")
        end

        puts "Project created successfully!"
        puts "Run: cd #{name} && bundle install && nightingale run app.rb"
      else
        puts "Error: Frontend template not found at #{frontend_template}"
      end
    end

    def self.run(script_path)
      script_path = File.expand_path(script_path)
      unless File.exist?(script_path)
        puts "Error: Script not found: #{script_path}"
        exit 1
      end

      puts "Starting Nightingale..."
      puts "Script: #{script_path}"

      # Start Backend (Sinatra)
      server_pid = fork do
        ENV['NIGHTINGALE_SCRIPT'] = script_path
        # Suppress Sinatra startup logs if needed, or keep them
        require 'nightingale/server'
        Nightingale::Server.run!
      end

      # Start Frontend (Vite)
      # Check if we are in a project with a frontend folder
      frontend_dir = File.join(Dir.pwd, 'frontend')
      vite_pid = nil

      if File.directory?(frontend_dir)
        puts "Starting Frontend (Vite)..."
        vite_pid = fork do
          Dir.chdir(frontend_dir)
          exec "npm run dev"
        end
      else
        # If no local frontend, maybe we should serve the gem's frontend?
        # For now, warn.
        puts "Warning: 'frontend' directory not found. UI might not load."
      end

      trap("INT") do
        puts "\nStopping..."
        Process.kill("TERM", server_pid)
        Process.kill("TERM", vite_pid) if vite_pid
        Process.wait(server_pid)
        Process.wait(vite_pid) if vite_pid
        exit
      end

      Process.wait(server_pid)
    end
  end
end
