#!/bin/bash

# Load configuration
source config.cfg

# Function to fetch stock price
fetch_price() {
    local response=$(curl -s "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$STOCK_SYMBOL&interval=1min&apikey=$API_KEY")
    echo "API Response: $response"  # Debug output
    
    local price=$(echo "$response" | jq -r '.["Time Series (1min)"] | to_entries | .[0].value."1. open"')
    echo $price
}

# Function to log price and check thresholds
log_price() {
    local price=$(fetch_price)  # Fetch the current stock price
    echo "Fetched price: $price"  # Log the fetched price for debugging
    
    # Log the date, stock symbol, and price to the log file
    echo "$(date) - $STOCK_SYMBOL: $price" >> $LOG_FILE

    # Check if the price is a valid number
    if [[ ! $price =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid price fetched - $price"  # Log an error message if price is invalid
        return
    fi

    # Compare the price against thresholds
    if (( $(echo "$price > $THRESHOLD_UP" | bc -l) )); then
        echo "ALERT: $STOCK_SYMBOL price has crossed above $THRESHOLD_UP!"
    elif (( $(echo "$price < $THRESHOLD_DOWN" | bc -l) )); then
        echo "ALERT: $STOCK_SYMBOL price has dropped below $THRESHOLD_DOWN!"
    fi
}

# Main loop
while true; do
    log_price  # Call the log_price function
    sleep 300  # Wait for 5 minutes before checking again
done
