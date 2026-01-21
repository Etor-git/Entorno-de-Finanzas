import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime
import mysql.connector
import matplotlib.pyplot as plt


#CONEXIÓN A MYSQL
def conectar_mysql():
    return mysql.connector.connect(
        host="localhost",      # Cambiar si usas otro host
        user="root",           # Tu usuario de MySQL
        password="123456789", # <-- CAMBIA ESTO
        database="gastos_app"
    )


#GUARDAR GASTO
def guardar_gasto():
    concepto = entry_concepto.get()
    cantidad = entry_cantidad.get()

    if concepto == "" or cantidad == "":
        messagebox.showerror("Error", "Debes llenar todos los campos")
        return

    try:
        cantidad = float(cantidad)
    except:
        messagebox.showerror("Error", "La cantidad debe ser un número")
        return

    fecha = datetime.now().strftime("%Y-%m-%d")
    hora = datetime.now().strftime("%H:%M:%S")

    conn = conectar_mysql()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO gastos (fecha, hora, concepto, cantidad) VALUES (%s, %s, %s, %s)",
        (fecha, hora, concepto, cantidad)
    )

    conn.commit()
    conn.close()

    entry_concepto.delete(0, tk.END)
    entry_cantidad.delete(0, tk.END)

    messagebox.showinfo("Éxito", "Gasto guardado correctamente")
    ver_gastos_dia()


# FUNCION DE COMO VER EL RESUMEN DEL DÍA
def ver_gastos_dia():
    fecha_hoy = datetime.now().strftime("%Y-%m-%d")

    conn = conectar_mysql()
    cursor = conn.cursor()
    cursor.execute("SELECT hora, concepto, cantidad FROM gastos WHERE fecha = %s ORDER BY hora ASC", (fecha_hoy,))
    resultados = cursor.fetchall()
    conn.close()

    tree.delete(*tree.get_children())  # Limpiar tabla

    total = 0

    for hora, concepto, cantidad in resultados:
        tree.insert("", "end", values=(hora, concepto, cantidad))
        total += cantidad

    label_total.config(text=f"Total gastado hoy: ${total:.2f}")


#GRAFICAR GASTOS SEMANA
def graficar_semana():
    conn = conectar_mysql()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT fecha, SUM(cantidad)
        FROM gastos
        GROUP BY fecha
        ORDER BY fecha ASC
        LIMIT 7
    """)

    resultados = cursor.fetchall()
    conn.close()

    if not resultados:
        messagebox.showinfo("Sin datos", "No hay gastos suficientes para graficar.")
        return

    # Invertir para mostrar cronológicamente
    # resultados.reverse()

    fechas = [str(r[0]) for r in resultados]
    totales = [float(r[1]) for r in resultados]

    plt.figure(figsize=(8, 4))
    plt.plot(fechas, totales, marker="o")
    plt.title("Gastos de los últimos 7 días")
    plt.xlabel("Fecha")
    plt.ylabel("Total gastado ($)")
    plt.grid(True)
    plt.tight_layout()
    plt.show()


#INTERFAZ GRÁFICA
root = tk.Tk()
root.title("Control de Gastos")
root.geometry("600x500")

# Título
titulo = tk.Label(root, text="Registro de Gastos", font=("Arial", 18))
titulo.pack(pady=10)

# Frame de entradas
frame = tk.Frame(root)
frame.pack(pady=10)

tk.Label(frame, text="Concepto:").grid(row=0, column=0, padx=5, pady=5)
entry_concepto = tk.Entry(frame, width=30)
entry_concepto.grid(row=0, column=1)

tk.Label(frame, text="Cantidad:").grid(row=1, column=0, padx=5, pady=5)
entry_cantidad = tk.Entry(frame, width=30)
entry_cantidad.grid(row=1, column=1)

# Botón guardar
btn_guardar = tk.Button(root, text="Guardar gasto", command=guardar_gasto, width=20, bg="lightgreen")
btn_guardar.pack(pady=10)

# Tabla de gastos
tree = ttk.Treeview(root, columns=("Hora", "Concepto", "Cantidad"), show="headings", height=10)
tree.heading("Hora", text="Hora")
tree.heading("Concepto", text="Concepto")
tree.heading("Cantidad", text="Cantidad")
tree.pack(pady=10)

# Total del día
label_total = tk.Label(root, text="Total gastado hoy: $0.00", font=("Arial", 14))
label_total.pack(pady=5)

# Botón para graficar
btn_grafica = tk.Button(root, text="Mostrar gráfica semanal", command=graficar_semana, width=25, bg="lightblue")
btn_grafica.pack(pady=10)

# Cargar gastos del día al iniciar
ver_gastos_dia()

root.mainloop()
