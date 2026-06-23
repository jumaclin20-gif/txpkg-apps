#!/data/data/com.termux/files/usr/bin/bash
APP_DIR=$1
mkdir -p $APP_DIR/bin
echo "[*] Installing PyPDF2 + rich - no Rust needed..."
pip install --no-cache-dir PyPDF2==3.0.1 tabulate rich==13.7.1
cat > $APP_DIR/bin/mpesa-analyzer << 'PYEOF'
#!/data/data/com.termux/files/usr/bin/python
import PyPDF2, sys, re, os
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich import box
console = Console()
def show_banner():
    os.system('clear')
    banner = """
    ███╗ ███╗ ██████╗ ███████╗███████╗ █████╗
    ████╗ ████║ ██╔══██╗██╔════╝██╔══██╗
    ██╔████╔██║█████╗██████╔╝█████╗ ███████╗███████║
    ██║╚██╔╝██║╚════╝██╔═══╝ ██╔══╝ ╚════██║██╔══██║
    ██║ ╚═╝ ██║ ██║ ███████╗███████║██║ ██║
    ╚═╝ ╚══════╝╚══════╝╚═╝ ╚═╝
                 STATEMENT ANALYZER v1.0
                 by jumaclin20-gif
    """
    console.print(Panel(banner, style="bold green", box=box.DOUBLE))
def analyze_mpesa(pdf_path):
    show_banner()
    console.print(f"[yellow]Analyzing:[/yellow] {pdf_path}\n")
    try:
        total_in = 0
        total_out = 0
        txns = []
        with console.status("[bold green]Reading PDF..."):
            with open(pdf_path, 'rb') as file:
                reader = PyPDF2.PdfReader(file)
                text = ""
                for page in reader.pages:
                    text += page.extract_text()
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
        if not txns:
            console.print("[bold red]No M-Pesa transactions found[/bold red]")
            return
        table = Table(title="Recent Transactions", box=box.ROUNDED)
        table.add_column("Date", style="cyan")
        table.add_column("Amount", style="magenta")
        table.add_column("Type", style="green")
        for row in txns[-10:]:
            table.add_row(*row)
        console.print(table)
        console.print()
        summary = f"""
[bold green]Total IN:[/bold green]  KSH {total_in:,.2f}
[bold red]Total OUT:[/bold red] KSH {total_out:,.2f}
[bold yellow]NET:[/bold yellow]       KSH {total_in - total_out:,.2f}
[dim]Analyzed {len(txns)} transactions[/dim]
        """
        console.print(Panel(summary, title="FINANCIAL SUMMARY", border_style="blue"))
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")
if __name__ == "__main__":
    if len(sys.argv) < 2:
        show_banner()
        console.print("Usage: mpesa-analyzer <statement.pdf>")
        console.print("[dim]Example: mpesa-analyzer ~/storage/downloads/statement.pdf[/dim]")
    else:
        analyze_mpesa(sys.argv[1])
PYEOF
chmod +x $APP_DIR/bin/mpesa-analyzer
echo "[✓] Done - PyPDF2 only"
