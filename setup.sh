#!/bin/bash

# Kickback App Setup Script
# Downloads and configures Apple's OpenELM-3B model for on-device inference

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="${SCRIPT_DIR}/KickbackApp/Resources/Models"
OPENELM_MODEL_URL="https://huggingface.co/apple/OpenELM-3B/resolve/main"
MODEL_FILES=(
    "config.json"
    "pytorch_model.bin"
    "tokenizer.json"
    "tokenizer_config.json"
    "vocab.json"
    "merges.txt"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    Kickback App Setup Script    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed."
        exit 1
    fi
    
    # Check if python3 is available for potential model conversion
    if ! command -v python3 &> /dev/null; then
        print_warning "python3 not found. Model conversion may not be available."
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "KickbackApp.xcodeproj/project.pbxproj" ]]; then
        print_error "This script must be run from the root of the Kickback project directory."
        exit 1
    fi
    
    print_success "Dependencies checked"
}

create_directories() {
    print_step "Creating directory structure..."
    
    mkdir -p "${MODELS_DIR}"
    mkdir -p "${SCRIPT_DIR}/temp_download"
    
    print_success "Directory structure created"
}

download_model() {
    print_step "Downloading OpenELM-3B model files..."
    
    local temp_dir="${SCRIPT_DIR}/temp_download"
    local total_size=0
    
    for file in "${MODEL_FILES[@]}"; do
        local url="${OPENELM_MODEL_URL}/${file}"
        local output_path="${temp_dir}/${file}"
        
        echo "  Downloading ${file}..."
        
        if curl -L --fail --progress-bar "${url}" -o "${output_path}"; then
            local file_size=$(du -h "${output_path}" | cut -f1)
            echo "    ✓ Downloaded ${file} (${file_size})"
        else
            print_error "Failed to download ${file}"
            cleanup_temp
            exit 1
        fi
    done
    
    print_success "All model files downloaded"
}

verify_model_size() {
    print_step "Verifying model bundle size..."
    
    local temp_dir="${SCRIPT_DIR}/temp_download"
    local total_size_bytes=$(du -sb "${temp_dir}" | cut -f1)
    local total_size_mb=$((total_size_bytes / 1024 / 1024))
    
    echo "  Total model size: ${total_size_mb} MB"
    
    # Check if size is within reasonable bounds (OpenELM-3B should be ~3-6 GB)
    if [[ ${total_size_mb} -lt 1000 ]]; then
        print_error "Model size seems too small (${total_size_mb} MB). Download may be incomplete."
        cleanup_temp
        exit 1
    elif [[ ${total_size_mb} -gt 8000 ]]; then
        print_error "Model size exceeds 8GB limit (${total_size_mb} MB). This may cause app store rejection."
        cleanup_temp
        exit 1
    fi
    
    print_success "Model size verified (${total_size_mb} MB)"
}

install_model() {
    print_step "Installing model files to project..."
    
    local temp_dir="${SCRIPT_DIR}/temp_download"
    
    # Move files to final destination
    for file in "${MODEL_FILES[@]}"; do
        if [[ -f "${temp_dir}/${file}" ]]; then
            mv "${temp_dir}/${file}" "${MODELS_DIR}/"
            echo "  ✓ Installed ${file}"
        else
            print_error "Missing file: ${file}"
            exit 1
        fi
    done
    
    print_success "Model files installed to ${MODELS_DIR}"
}

update_xcode_project() {
    print_step "Adding model files to Xcode project..."
    
    # Note: This is a simplified approach. In a production setup, you might want to
    # use xcodeproj gem or similar tools for more robust project file manipulation
    
    echo "  Model files are now in Resources/Models/"
    echo "  You may need to manually add them to your Xcode project if not already included in bundle resources."
    
    print_success "Model integration ready"
}

create_config() {
    print_step "Creating app configuration..."
    
    local config_file="${SCRIPT_DIR}/KickbackApp/Resources/Config/AppConfig.plist"
    mkdir -p "$(dirname "${config_file}")"
    
    cat > "${config_file}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LLMConfiguration</key>
    <dict>
        <key>ModelName</key>
        <string>OpenELM-3B</string>
        <key>ModelPath</key>
        <string>Models</string>
        <key>MaxTokens</key>
        <integer>512</integer>
        <key>Temperature</key>
        <real>0.7</real>
        <key>TopP</key>
        <real>0.9</real>
        <key>TimeoutSeconds</key>
        <integer>30</integer>
    </dict>
    <key>AppConfiguration</key>
    <dict>
        <key>OfflineMode</key>
        <true/>
        <key>AnalyticsEnabled</key>
        <false/>
        <key>LogLevel</key>
        <string>info</string>
    </dict>
</dict>
</plist>
EOF
    
    print_success "Configuration file created"
}

cleanup_temp() {
    print_step "Cleaning up temporary files..."
    rm -rf "${SCRIPT_DIR}/temp_download"
    print_success "Cleanup completed"
}

validate_installation() {
    print_step "Validating installation..."
    
    local missing_files=0
    for file in "${MODEL_FILES[@]}"; do
        if [[ ! -f "${MODELS_DIR}/${file}" ]]; then
            print_error "Missing model file: ${file}"
            ((missing_files++))
        fi
    done
    
    if [[ ${missing_files} -gt 0 ]]; then
        print_error "Installation validation failed. ${missing_files} files are missing."
        exit 1
    fi
    
    print_success "Installation validated successfully"
}

print_completion_message() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}    Setup Complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open KickbackApp.xcodeproj in Xcode"
    echo "2. Build the project to verify MLX integration"
    echo "3. Test the LLMService with the installed model"
    echo ""
    echo "Model location: ${MODELS_DIR}"
    echo "Configuration: KickbackApp/Resources/Config/AppConfig.plist"
    echo ""
    echo -e "${BLUE}Happy coding! 🚀${NC}"
}

# Main execution
main() {
    print_header
    
    check_dependencies
    create_directories
    download_model
    verify_model_size
    install_model
    update_xcode_project
    create_config
    cleanup_temp
    validate_installation
    
    print_completion_message
}

# Handle script interruption
trap cleanup_temp EXIT

# Run main function
main "$@"