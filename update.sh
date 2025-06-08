#!/bin/bash

# Function to send a fancy zenity notification
send_zenity_notification() {
    local title="$1"
    local message="$2"
    local type="${3:-info}"
    
    case "$type" in
        "error")
            zenity --error --title="$title" --text="$message" --width=400 --height=200
            ;;
        "warning")
            zenity --warning --title="$title" --text="$message" --width=400 --height=200
            ;;
        *)
            zenity --info --title="$title" --text="$message" --width=500 --height=300
            ;;
    esac
}

# Function to get package version information
get_package_versions() {
    local package_name="$1"
    local package_manager="$2"
    
    case "$package_manager" in
        "pacman")
            # Get installed version
            local installed_version=$(pacman -Q "$package_name" 2>/dev/null | awk '{print $2}')
            # Get available version
            local available_version=$(pacman -Si "$package_name" 2>/dev/null | grep "Version" | awk '{print $3}')
            echo "$installed_version → $available_version"
            ;;
        "flatpak")
            # For flatpak, we'll show the app ID as version info is harder to extract
            echo "Update available"
            ;;
    esac
}

# Function to check if it's Sunday
is_sunday() {
    [[ "$(date +%u)" -eq 7 ]]
}

# Function to update pacman packages and collect detailed update information
update_pacman() {
    local update_details=""
    sudo pacman -Sy > /dev/null
    
    # Get list of packages to update with version info
    local updates=$(pacman -Qu)
    
    if [ -n "$updates" ]; then
        echo "📦 PACMAN UPDATES:" > /tmp/pacman_updates.txt
        echo "==================" >> /tmp/pacman_updates.txt
        
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                local pkg_name=$(echo "$line" | awk '{print $1}')
                local old_version=$(echo "$line" | awk '{print $2}')
                local new_version=$(echo "$line" | awk '{print $4}')
                echo "• $pkg_name: $old_version → $new_version" >> /tmp/pacman_updates.txt
                update_details+="$pkg_name "
            fi
        done <<< "$updates"
        
        echo "" >> /tmp/pacman_updates.txt
        
        # Perform the actual update
        sudo pacman -Syu --noconfirm > /dev/null 2>&1
    fi
    
    echo "$update_details"
}

# Function to update flatpak packages and collect detailed update information
update_flatpak() {
    local update_details=""
    
    if command -v flatpak >/dev/null 2>&1; then
        # Check for updates first
        local updates=$(flatpak remote-ls --updates 2>/dev/null)
        
        if [ -n "$updates" ] && [ "$updates" != "" ]; then
            echo "📱 FLATPAK UPDATES:" >> /tmp/flatpak_updates.txt
            echo "===================" >> /tmp/flatpak_updates.txt
            
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local app_id=$(echo "$line" | awk '{print $1}')
                    local app_name=$(echo "$line" | awk '{print $2}' | sed 's/.*\///g')
                    echo "• $app_name ($app_id)" >> /tmp/flatpak_updates.txt
                    update_details+="$app_name "
                fi
            done <<< "$updates"
            
            echo "" >> /tmp/flatpak_updates.txt
            
            # Perform the actual update
            flatpak update -y > /dev/null 2>&1
        fi
    fi
    
    echo "$update_details"
}

# Function to create and display comprehensive update summary
show_update_summary() {
    local pacman_updates="$1"
    local flatpak_updates="$2"
    
    # Create summary file
    echo "🎉 SYSTEM UPDATE COMPLETED" > /tmp/update_summary.txt
    echo "=========================" >> /tmp/update_summary.txt
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> /tmp/update_summary.txt
    echo "" >> /tmp/update_summary.txt
    
    local total_updates=0
    
    # Add pacman updates if any
    if [ -n "$pacman_updates" ] && [ -f /tmp/pacman_updates.txt ]; then
        cat /tmp/pacman_updates.txt >> /tmp/update_summary.txt
        total_updates=$((total_updates + $(echo "$pacman_updates" | wc -w)))
    fi
    
    # Add flatpak updates if any
    if [ -n "$flatpak_updates" ] && [ -f /tmp/flatpak_updates.txt ]; then
        cat /tmp/flatpak_updates.txt >> /tmp/update_summary.txt
        total_updates=$((total_updates + $(echo "$flatpak_updates" | wc -w)))
    fi
    
    if [ $total_updates -eq 0 ]; then
        echo "✅ No updates were available." >> /tmp/update_summary.txt
        echo "Your system is up to date!" >> /tmp/update_summary.txt
    else
        echo "📊 SUMMARY:" >> /tmp/update_summary.txt
        echo "============" >> /tmp/update_summary.txt
        echo "Total packages updated: $total_updates" >> /tmp/update_summary.txt
        
        if [ -n "$pacman_updates" ]; then
            echo "Pacman packages: $(echo "$pacman_updates" | wc -w)" >> /tmp/update_summary.txt
        fi
        
        if [ -n "$flatpak_updates" ]; then
            echo "Flatpak applications: $(echo "$flatpak_updates" | wc -w)" >> /tmp/update_summary.txt
        fi
    fi
    
    # Display the summary using zenity with text-info for better formatting
    zenity --text-info \
           --title="System Update Report - $(date '+%Y-%m-%d')" \
           --filename=/tmp/update_summary.txt \
           --width=600 \
           --height=500 \
           --font="monospace 10"
    
    # Clean up temporary files
    rm -f /tmp/pacman_updates.txt /tmp/flatpak_updates.txt /tmp/update_summary.txt
}

if is_sunday; then
    echo "Sunday detected - performing system updates..."
    
    # Clear any existing temporary files
    rm -f /tmp/pacman_updates.txt /tmp/flatpak_updates.txt /tmp/update_summary.txt
    
    # Perform updates and collect information
    pacman_updates=$(update_pacman)
    flatpak_updates=$(update_flatpak)
    
    # Show comprehensive summary
    show_update_summary "$pacman_updates" "$flatpak_updates"
else
    echo "Not Sunday - skipping updates"
fi

exit 0