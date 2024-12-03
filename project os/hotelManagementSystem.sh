#!/bin/bash

# Constants for colors
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"

# File paths
ROOMS_FILE="rooms.txt"
CUSTOMERS_FILE="customers.txt"

# Function: Initialize files
initializeFiles() {
    if [ ! -f $ROOMS_FILE ]; then
        touch $ROOMS_FILE
    fi
    if [ ! -f $CUSTOMERS_FILE ]; then
        touch $CUSTOMERS_FILE
    fi
}

# Function: Display a colored header
header() {
    clear
    echo -e "${CYAN}${BOLD}###########################################"
    echo -e "         Hotel Management System           "
    echo -e "###########################################${RESET}"
}

# Function: Add Room
addRoom() {
    header
    echo -e "${BLUE}######## Add Room ########${RESET}"
    echo "Enter Room Number: "
    read roomNumber
    if grep -q "^$roomNumber," $ROOMS_FILE; then
        echo -e "${RED}Room already exists!${RESET}"
    else
        echo "Type AC/Non-AC (A/N): "
        read ac
        echo "Type Comfort (S/N): "
        read comfort
        echo "Type Size (B/S): "
        read size
        echo "Daily Rent: "
        read rent
        echo "$roomNumber,$ac,$comfort,$size,$rent,0" >> $ROOMS_FILE
        echo -e "${GREEN}Room Added Successfully!${RESET}"
    fi
    read -p "Press any key to return to the main menu..."
}

# Function: Search Room
searchRoom() {
    header
    echo -e "${BLUE}######## Search Room ########${RESET}"
    echo "Enter Room Number: "
    read roomNumber
    if grep -q "^$roomNumber," $ROOMS_FILE; then
        roomDetails=$(grep "^$roomNumber," $ROOMS_FILE)
        IFS=',' read -r rNum ac comfort size rent status <<<"$roomDetails"
        echo -e "${CYAN}Room Details:${RESET}"
        echo -e "Room Number: ${YELLOW}$rNum${RESET}"
        echo -e "Type AC/Non-AC: ${YELLOW}$ac${RESET}"
        echo -e "Type Comfort: ${YELLOW}$comfort${RESET}"
        echo -e "Type Size: ${YELLOW}$size${RESET}"
        echo -e "Rent: ${YELLOW}$rent${RESET}"
        if [ "$status" -eq 1 ]; then
            echo -e "Status: ${RED}Reserved${RESET}"
        else
            echo -e "Status: ${GREEN}Available${RESET}"
        fi
    else
        echo -e "${RED}Room not found.${RESET}"
    fi
    read -p "Press any key to return to the main menu..."
}

# Function: Check-In Customer
checkIn() {
    header
    echo -e "${BLUE}######## Check-In ########${RESET}"
    echo "Enter Room Number: "
    read roomNumber
    if grep -q "^$roomNumber," $ROOMS_FILE; then
        roomDetails=$(grep "^$roomNumber," $ROOMS_FILE)
        IFS=',' read -r rNum ac comfort size rent status <<<"$roomDetails"
        if [ "$status" -eq 1 ]; then
            echo -e "${RED}Room is already booked.${RESET}"
        else
            echo "Enter Booking ID: "
            read bookingId
            echo "Enter Customer Name: "
            read customerName
            echo "Enter Address (City): "
            read address
            echo "Enter Phone Number: "
            read phone
            echo "Enter Check-In Date (YYYY-MM-DD): "
            read fromDate
            echo "Enter Check-Out Date (YYYY-MM-DD): "
            read toDate
            echo "Enter Advance Payment: "
            read advance
            echo "$roomNumber,$bookingId,$customerName,$address,$phone,$fromDate,$toDate,$advance" >> $CUSTOMERS_FILE
            sed -i "s/^$roomNumber,.*/$roomNumber,$ac,$comfort,$size,$rent,1/" $ROOMS_FILE
            echo -e "${GREEN}Customer Checked In Successfully!${RESET}"
        fi
    else
        echo -e "${RED}Room not found.${RESET}"
    fi
    read -p "Press any key to return to the main menu..."
}

# Function: Search Customer
searchCustomer() {
    header
    echo -e "${BLUE}######## Search Customer ########${RESET}"
    echo "Enter Customer Name: "
    read customerName
    found=0
    while IFS=',' read -r rNum bookingId cName address phone fromDate toDate advance; do
        if [ "$cName" == "$customerName" ]; then
            echo -e "${CYAN}Customer Details:${RESET}"
            echo -e "Customer Name: ${YELLOW}$cName${RESET}"
            echo -e "Room Number: ${YELLOW}$rNum${RESET}"
            echo -e "Address: ${YELLOW}$address${RESET}"
            echo -e "Phone: ${YELLOW}$phone${RESET}"
            found=1
        fi
    done < $CUSTOMERS_FILE
    if [ "$found" -eq 0 ]; then
        echo -e "${RED}Customer not found.${RESET}"
    fi
    read -p "Press any key to return to the main menu..."
}

# Function: Check-out Customer
checkOut() {
    header
    echo -e "${BLUE}Customer Check-Out${RESET}"
    echo -n "Enter Room Number: "
    read roomNumber

    tempFile=$(mktemp)
    roomFound=0
    customerFound=0

    while IFS=',' read -r rNo acType comfort size rent status; do
        if [ "$rNo" == "$roomNumber" ]; then
            roomFound=1
            if [ "$status" == "0" ]; then
                echo -e "${RED}Room is not reserved.${RESET}"
                echo "$rNo,$acType,$comfort,$size,$rent,$status" >> $tempFile
            else
                while IFS=',' read -r cRoom cBookingId cName cAddress cPhone cCheckIn cCheckOut cAdvance; do
                    if [ "$cRoom" == "$roomNumber" ]; then
                        customerFound=1
                        echo -e "${CYAN}Customer Name:${RESET} $cName"
                        echo -e "${CYAN}Address:${RESET} $cAddress"
                        echo -e "${CYAN}Phone:${RESET} $cPhone"
                        echo -e "${CYAN}Check-In Date:${RESET} $cCheckIn"
                        echo -e "${CYAN}Check-Out Date:${RESET} $cCheckOut"

                        # Calculate days stayed and bill
                        daysStayed=$(( ($(date -d "$cCheckOut" '+%s') - $(date -d "$cCheckIn" '+%s')) / 86400 ))
                        totalBill=$((daysStayed * rent))
                        payable=$((totalBill - cAdvance))
                        echo -e "${CYAN}Total Bill:${RESET} $totalBill"
                        echo -e "${CYAN}Advance Paid:${RESET} $cAdvance"
                        echo -e "${CYAN}Amount Payable:${RESET} $payable"

                        # Mark room as available
                        echo "$rNo,$acType,$comfort,$size,$rent,0" >> $tempFile
                    fi
                done < $CUSTOMERS_FILE
            fi
        else
            echo "$rNo,$acType,$comfort,$size,$rent,$status" >> $tempFile
        fi
    done < $ROOMS_FILE

    mv $tempFile $ROOMS_FILE

    if [ $roomFound -eq 0 ]; then
        echo -e "${RED}Room not found.${RESET}"
    elif [ $customerFound -eq 0 ]; then
        echo -e "${RED}No customer information found for the room.${RESET}"
    fi

    read -p "Press any key to return to the menu..."
}

# Function: Main Menu
mainMenu() {
    while true; do
        header
        echo -e "${CYAN}1. Add Room"
        echo -e "2. Search Room"
        echo -e "3. Check-In Customer"
        echo -e "4. Search Customer"
        echo -e "5. Check-Out Customer"
        echo -e "6. Exit${RESET}"
        echo -n "Enter your choice: "
        read choice
        case $choice in
            1) addRoom ;;
            2) searchRoom ;;
            3) checkIn ;;
            4) searchCustomer ;;
            5) checkOut ;;
            6) echo -e "${GREEN}Thank you for using the system. Goodbye!${RESET}"; exit ;;
            *) echo -e "${RED}Invalid choice!${RESET}" ;;
        esac
    done
}

# Initialize files and start the program
initializeFiles
mainMenu
