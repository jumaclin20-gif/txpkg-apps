#!/data/data/com.termux/files/usr/bin/bash
APP_DIR=$1
mkdir -p $APP_DIR/bin

# Install python deps
echo "[*] Installing pdfplumber..."
pip install pdfplumber tabulate > /dev/null 2>&1

# Create the actual analyzer script
cat > $APP_DIR/bin/mpesa-analyzer << 'PYEOF'
#!/data/data/com.termux/files/usr/bin/python
import pdfplumber
import sys
import re
from tabulate import tabulate

def analyze_mpesa(pdf_path):
    try:
        total_in = 0
        total_out = 0
        txns = []
        
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if not text: continue
                
                # Match M-Pesa transaction lines
                # Example: 01-09-25 12:34 PM KSH 500.00 Received from JOHN DOE
                pattern = r'(\d{2}-\d{2}).*?KSH\s+([\d,]+\.\d{2})\s+(Received from|Paid to|Withdraw|Deposit)'
                matches = re.findall(pattern, text)
                
                for date, amount, t_type in matches:
                    amt = float(amount.replace(',', ''))
                    if 'Received' in t_type or 'Deposit' in t_type:
                        total_in += amt
                        txns.append([date, f"+{amt}", t_type])
                    else:
                        total_out += amt
                       
txpkg install mpesa-analyzer

ls

cd ~/txpkg-apps/mpesa-analyzer

cat > install.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
APP_DIR=$1
mkdir -p $APP_DIR/bin

echo "[*] Installing pdfplumber..."
pip install pdfplumber tabulate

cat > $APP_DIR/bin/mpesa-analyzer << 'PYEOF'
#!/data/data/com.termux/files/usr/bin/python
import pdfplumber
import sys
import re
from tabulate import tabulate

def analyze_mpesa(pdf_path):
    try:
        total_in = 0
        total_out = 0
        txns = []
        
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if not text: continue
                
                pattern = r'(\d{2}-\d{2}).*?KSH\s+([\d,]+\.\d{2})\s+(Received from|Paid to|Withdraw|Deposit|Buy Goods|Pay Bill)'
                matches = re.findall(pattern, text)
                
                for date, amount, t_type in matches:
                    amt = float(amount.replace(',', ''))
                    if 'Received' in t_type or 'Deposit' in t_type:
                        total_in += amt
                        txns.append([date, f"+{amt:,.2f}", t_type])
                    else:
                        total_out += amt
                        txns.append([date, f"-{amt:,.2f}", t_type])
        
        print(f"\n=== M-PESA ANALYSIS: {pdf_path} ===\n")
        if txns:
            print(tabulate(txns[-10:], headers=["Date", "Amount", "Type"], tablefmt="simple"))
            print(f"\nTotal IN:  KSH {total_in:,.2f}")
            print(f"Total OUT: KSH {total_out:,.2f}")
            print(f"Net:       KSH {total_in - total_out:,.2f}")
            print(f"\nAnalyzed {len(txns)} transactions")
        else:
            print("No transactions found. Check if this is an M-Pesa statement PDF.")
            
    except FileNotFoundError:
        print(f"Error: File '{pdf_path}' not found")
    except Exception as e:
        print(f"Error reading PDF: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mpesa-analyzer <statement.pdf>")
    else:
        analyze_mpesa(sys.argv[1])
PYEOF

chmod +x $APP_DIR/bin/mpesa-analyzer
echo "[✓] mpesa-analyzer upgraded with PDF support"
