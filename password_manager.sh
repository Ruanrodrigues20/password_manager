#!/bin/bash

USER_DIR="$HOME/.manager_password/$(whoami)"
mkdir -p "$USER_DIR"
PASSWORD_FILE="$USER_DIR/passwords.enc"
TEMP_FILE="$USER_DIR/passwords.tmp"

# Function to derive the key from the master password
generate_key_from_master_password() {
    master_password=$(dialog --title "Enter your master password" --passwordbox "Please enter your master password to generate the encryption key:" 10 50 2>&1 >/dev/tty)
    if [[ -z "$master_password" ]]; then
        dialog --msgbox "Master password not provided. Please try again." 10 50
        return 1
    fi
    echo "$master_password" | openssl dgst -sha256 -binary | head -c 32 > "$USER_DIR/temp_keyfile"
    chmod 600 "$USER_DIR/temp_keyfile"
}

# Function to encrypt the passwords
encrypt_passwords() {
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    openssl enc -aes-256-cbc -salt -in "$TEMP_FILE" -out "$PASSWORD_FILE" -pass file:"$USER_DIR/temp_keyfile" 2>/dev/null
}

# Function to decrypt the passwords
decrypt_passwords() {
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    openssl enc -aes-256-cbc -d -in "$PASSWORD_FILE" -out "$TEMP_FILE" -pass file:"$USER_DIR/temp_keyfile" 2>/dev/null
}

# Function to backup the encrypted password file
backup_passwords() {
    cp "$PASSWORD_FILE" "$PASSWORD_FILE.bak"
    dialog --msgbox "Backup of the encrypted password file successfully created at $PASSWORD_FILE.bak." 10 50
}

# Function to list all saved services
list_services() {
    # Ensure the temporary file exists before reading
    touch "$TEMP_FILE"
    decrypt_passwords
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error decrypting passwords. Please try again." 10 50
        return 1
    fi

    services=$(awk -F ' | ' '{print $1}' "$TEMP_FILE" | nl)
    dialog --msgbox "All services with saved passwords:\n$services" 15 50
}

# Function to add a password
add_password() {
    # Check if the encrypted password file exists
    if [[ ! -f "$PASSWORD_FILE" ]]; then
        touch "$TEMP_FILE"
        encrypt_passwords
    fi

    decrypt_passwords
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error decrypting passwords. Please try again." 10 50
        return 1
    fi

    service=$(dialog --title "Add Password" --inputbox "Enter the service name:" 10 50 2>&1 >/dev/tty)
    username=$(dialog --title "Add Password" --inputbox "Enter the username:" 10 50 2>&1 >/dev/tty)
    password=$(dialog --title "Add Password" --insecure --inputbox "Enter the password:" 10 50 2>&1 >/dev/tty)

    # Add the password to the temporary file
    echo "$service | $username | $password" >> "$TEMP_FILE"

    # Re-encrypt the passwords and remove the temporary file
    encrypt_passwords
    dialog --msgbox "Password successfully saved!" 10 50
}

# Function to search for a password
search_password() {
    decrypt_passwords
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error decrypting passwords. Please try again." 10 50
        return 1
    fi

    service=$(dialog --title "Search Password" --inputbox "Enter the exact name of the service you want to search for:" 10 50 2>&1 >/dev/tty)
    found=0
    result=$(grep "^$service |" "$TEMP_FILE")

    if [[ -n "$result" ]]; then
        dialog --msgbox "$result" 15 50
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        dialog --msgbox "No password found for the service '$service'." 10 50
    fi
}

# Function to remove a password
remove_password() {
    decrypt_passwords
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error decrypting passwords. Please try again." 10 50
        return 1
    fi

    service=$(dialog --title "Remove Password" --inputbox "Enter the exact name of the service you want to remove:" 10 50 2>&1 >/dev/tty)

    if grep -q "^$service |" "$TEMP_FILE"; then
        backup_passwords
        grep -v "^$service |" "$TEMP_FILE" > "${TEMP_FILE}.new"
        mv "${TEMP_FILE}.new" "$TEMP_FILE"
        encrypt_passwords
        dialog --msgbox "All entries for the service '$service' have been successfully removed!" 10 50
    else
        dialog --msgbox "No password found for the service '$service'." 10 50
    fi
}

# Function to update a service password
update_password() {
    decrypt_passwords
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error decrypting passwords. Please try again." 10 50
        return 1
    fi

    service=$(dialog --title "Update Password" --inputbox "Enter the exact name of the service you want to update:" 10 50 2>&1 >/dev/tty)

    if grep -q "^$service |" "$TEMP_FILE"; then
        new_password=$(dialog --title "Update Password" --insecure --inputbox "Enter the new password for the service '$service':" 10 50 2>&1 >/dev/tty)

        # Update the password in the temporary file
        awk -F ' | ' -v srv="$service" -v new_pass="$new_password" '
        BEGIN { OFS=" | " }
        $1 == srv { $3 = new_pass }
        { print }' "$TEMP_FILE" > "${TEMP_FILE}.new"

        mv "${TEMP_FILE}.new" "$TEMP_FILE"
        encrypt_passwords
        dialog --msgbox "Password for the service '$service' successfully updated!" 10 50
    else
        dialog --msgbox "No entry found for the service '$service'." 10 50
    fi
}

# Function to display the menu
show_menu() {
    action=$(dialog --menu "Password Manager" 15 50 7 \
        1 "Add Password" \
        2 "Search Password (Requires authentication)" \
        3 "Show Saved Services (Requires authentication)" \
        4 "Remove Password (Requires authentication)" \
        5 "Update Password (Requires authentication)" \
        6 "Backup Encrypted Passwords" \
        7 "Exit" \
        2>&1 >/dev/tty)

    case $action in
        1)  
            generate_key_from_master_password
            add_password
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        2)
            generate_key_from_master_password
            search_password
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        3)
            generate_key_from_master_password
            list_services
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        4)
            generate_key_from_master_password
            remove_password
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        5)
            generate_key_from_master_password
            update_password
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        6)
            generate_key_from_master_password
            backup_passwords
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            ;;
        7)
            dialog --msgbox "Exiting the Password Manager." 10 50
            clear
            rm -f "$USER_DIR/temp_keyfile" "$TEMP_FILE"  # Remove temporary files upon exit
            exit
            ;;
        *)
            dialog --msgbox "Invalid option. Please try again." 10 50
            ;;
    esac
}

# Main program
main() {
    if [[ ! -f "$PASSWORD_FILE" ]]; then
        generate_key_from_master_password
    fi    
    
    while true; do
        show_menu
    done
}

main
