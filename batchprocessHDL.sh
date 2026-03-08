#!/bin/bash

# 1. Select the Target Device once for the whole batch
read -p "Enter the target device (e.g., sdb): " TARGET_DEV
[[ "$TARGET_DEV" != /dev/* ]] && TARGET_DEV="/dev/$TARGET_DEV"

# Verify device exists before proceeding
if [ ! -b "$TARGET_DEV" ]; then
    echo "Error: $TARGET_DEV is not a valid block device."
    exit 1
fi

# 2. Gather info for all ISOs in the current directory
declare -A GAMES
ISO_FILES=(*.iso)

if [ "${ISO_FILES[0]}" == "*.iso" ]; then
    echo "No ISO files found in the current directory."
    exit 1
fi

echo "--- Pre-Process Setup ---"
for ISO in "${ISO_FILES[@]}"; do
    echo "Processing: $ISO"
    
    # Extract ID
    GAME_ID=$(./hdl_dump cdvd_info "$ISO" | grep -oP '[A-Z]{4}_[0-9]{3}\.[0-9]{2}' | head -1)
    
    if [ -z "$GAME_ID" ]; then
        echo " ! Warning: Could not find ID for $ISO. Skipping..."
        continue
    fi
    
    read -p " Enter OPL display name for $GAME_ID: " DISPLAY_NAME
    
    # Store data for the batch run
    GAMES["$ISO"]="$GAME_ID|$DISPLAY_NAME"
done

# 3. Execution Phase
echo -e "\n--- Starting Batch Injection ---"
for ISO in "${!GAMES[@]}"; do
    # Split the stored string back into ID and Name
    IFS='|' read -r G_ID G_NAME <<< "${GAMES[$ISO]}"
    
    echo "Injecting: $G_NAME ($G_ID)..."
    
    # Actual command execution
    sudo ./hdl_dump inject_dvd "$TARGET_DEV" "$G_NAME" "$ISO" "$G_ID" *u4
    
    if [ $? -eq 0 ]; then
        echo "Successfully injected $G_NAME."
    else
        echo "FAILED to inject $G_NAME."
    fi
    echo "---------------------------"
done

echo "Batch process complete."
