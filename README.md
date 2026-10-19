# 🖥️ HardwareQuoteB2B — Plataforma Corporativa de Cotización y Validación de Infraestructura

![Platform](https://img.shields.io/badge/Platform-iOS%2017.0%2B-000000?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%20%7C%206.0-F05138?style=flat-square&logo=swift)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20Hybrid%20(SwiftUI%20%2B%20UIKit)-33568C?style=flat-square)
![Backend](https://img.shields.io/badge/Backend-Firebase%20(Auth%20%7C%20RTDB%20%7C%20Storage)-FFCA28?style=flat-square&logo=firebase)

## 📋 Resumen Ejecutivo

**HardwareQuoteB2B** es una aplicación empresarial nativa para iOS y iPadOS diseñada para ingenieros preventa, arquitectos de hardware y técnicos ensambladores. Permite configurar servidores y estaciones de trabajo de alto rendimiento en tiempo real, auditando automáticamente la demanda energética (Watts) frente a la capacidad de la fuente de poder, calculando márgenes de utilidad B2B con tasas de cambio oficiales vía REST API y emitiendo propuestas formales en formato PDF vectorial sincronizadas de manera atómica entre almacenamiento local y la nube.

El proyecto implementa una **arquitectura MVVM híbrida** que combina el poder declarativo y reactivo de **SwiftUI** con controladores **UIKit** interoperables mediante `UIViewControllerRepresentable`, cumpliendo rigurosamente con las *Human Interface Guidelines (HIG)* de Apple.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología / Framework | Propósito en el Proyecto |
| :--- | :--- | :--- |
| **Interfaz Reactiva** | `SwiftUI` + `Observation (@Observable)` | Cotizador interactivo, almacén dinámico, formularios y medidor energético animado. |
| **Interoperabilidad Legacy** | `UIKit` (`UITableViewController`, `@IBOutlet`, `@IBAction`, `UIStoryboardSegue`) | Login corporativo, historial de cotizaciones, inspector técnico y puente `UIActivityViewController`. |
| **Persistencia Local** | `CoreData` (Stack Programático) + `SwiftData` | Persistencia transaccional offline de cotizaciones, clientes y catálogo de componentes. |
| **Backend & Nube** | `Firebase Auth`, `Realtime Database`, `Firebase Storage` | Autenticación de técnicos ensambladores, sincronización 1:1 en tiempo real y respaldo en la nube de PDFs. |
| **Red y Divisas** | `URLSession` (`async/await`) | Consumo de REST API para obtener el tipo de cambio oficial (`USD -> MXN`) con tolerancia a fallos. |
| **Multimedia y Hardware** | `AVFoundation` (`AVAudioRecorder`, `AVAudioPlayer`) | Grabación y reproducción de notas de voz técnicas con validación preventiva de permisos TCC (`NSMicrophoneUsageDescription`). |
| **Motor Documental** | `PDFKit` & `UIGraphicsPDFRenderer` | Generación vectorial de propuestas comerciales en memoria temporal (`temporaryDirectory`) y exportación vía `ShareSheet`. |
| **Calidad y Testing** | `XCTest` | Suite de pruebas unitarias para validar cálculo energético, subtotales, márgenes comerciales y precisión decimal. |

---

## ✨ Características Principales (Features)

### 1. Arquitectura MVVM Híbrida (SwiftUI + UIKit)
- **Flujo Reactivo en SwiftUI (`QuoteBuilderView`):** Interfaz minimalista con materiales translúcidos (`.ultraThinMaterial`), tipografía monoespaciada para cifras financieras y transiciones numéricas fluidas.
- **Módulos UIKit Integrados (`LoginViewController`, `HistorialCotizacionesViewController`, `ComponentesViewController`):** Demostración formal del ciclo de vida de `UIViewController`, celdas personalizadas, búsqueda con `UISearchBar`, `@IBOutlet`, `@IBAction` y navegación por `UIStoryboardSegue` coexistiendo con SwiftUI.

### 2. Almacén Dinámico y Gestión de Stock en Tiempo Real
- **Catálogo Interactivo (`CatalogoHardwareView`):** Filtrado instantáneo por categoría (`CPU`, `GPU`, `RAM`, `Placa`, `Fuente`) y búsqueda por modelo o socket.
- **Alta de Componentes (`CrearComponenteFormView`):** Formulario reactivo que permite registrar nuevos productos en el almacén en tiempo real e insertarlos directamente en la cotización activa.
- **Edición Ágil (*Swipe-to-Delete*):** Eliminación nativa deslizando hacia la izquierda (`.onDelete`) con recálculo inmediato del presupuesto y del consumo eléctrico.

### 3. Medidor Reactivo de Demanda Energética (Watts)
- Cálculo automático en tiempo real del consumo acumulado en Watts de los componentes seleccionados frente a la capacidad nominal de la fuente de poder.
- Retroalimentación visual mediante estados operativos (**Holgura Óptima**, **Carga Moderada**, **Límite Energético**) con animaciones `.spring`.

### 4. Persistencia Dual Atómica (CoreData $\leftrightarrow$ Firebase RTDB)
- **`HistorialManager` (Singleton):** Administra un `NSPersistentContainer` configurado 100% por código (`CotizacionEntity`).
- **Sincronización Determinista 1:1:** Cada cotización comparte el mismo `UUID` entre CoreData, el nodo `/historial_cotizaciones/{uuid}` de Firebase Realtime Database y el archivo PDF generado, garantizando creaciones y eliminaciones (`removeValue()`) bidireccionales sin registros huérfanos.

### 5. Motor de Exportación PDF y Respaldo en Firebase Storage
- Renderizado vectorial en tamaño Carta mediante `UIGraphicsPDFRenderer` en `FileManager.default.temporaryDirectory` para optimizar el almacenamiento del dispositivo.
- Subida asíncrona en segundo plano del comprobante PDF a **Firebase Storage** (`cotizaciones/{id}/documentos/`) y presentación de `UIActivityViewController` compatible con iPhone y iPad (`UIPopoverPresentationController`).

### 6. Notas de Voz Técnicas con `AVFoundation`
- Grabación y reproducción de especificaciones de ensamblaje desde el cotizador mediante `VoiceNoteManager`, con control de ciclo de vida (`deinit`), prevención de *retain cycles* (`[weak self]`) y verificación de privacidad TCC.

---

## 🔥 Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/) y registra una aplicación iOS con el Bundle ID:
   ```text
   miempresa.com.HardwareQuoteB2B
   ```
2. Habilita los siguientes servicios en la consola de Firebase:
   - **Authentication:** Proveedor *Correo electrónico/Contraseña*.
   - **Realtime Database:** Reglas de lectura/escritura para el nodo `/historial_cotizaciones`.
   - **Storage:** Reglas de almacenamiento para la ruta `/cotizaciones/{idCotizacion}/documentos/`.
3. Descarga el archivo `GoogleService-Info.plist` y colócalo dentro de la carpeta `HardwareQuoteB2B/HardwareQuoteB2B/`.

> **Nota de Resiliencia:** El proyecto cuenta con compilación condicional (`#if canImport(Firebase...)`) y *fallbacks* locales, por lo que puede compilarse y probarse en simulador incluso en entornos sin conexión a red.

---

## 🚀 Guía Rápida de Instalación

### Requisitos Previos
- **macOS:** Sonoma 14.5+ o Sequoia 15.0+
- **Xcode:** 16.0 o superior
- **iOS Target:** iOS 17.0+

### Pasos de Instalación y Ejecución

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/diegoaragonmurillo-sys/HardwareQuoteB2B.git
   cd HardwareQuoteB2B
   ```

2. **Abrir el proyecto en Xcode:**
   ```bash
   open HardwareQuoteB2B.xcodeproj
   ```

3. **Resolver paquetes de Swift Package Manager (SPM):**
   - En Xcode, dirígete a **File > Packages > Resolve Package Versions** para descargar automáticamente las dependencias de `firebase-ios-sdk` (`FirebaseAuth`, `FirebaseDatabase`, `FirebaseStorage`, `FirebaseCore`).

4. **Compilar y Ejecutar:**
   - Selecciona un simulador de iPhone o iPad (ej. *iPhone 16 Pro*) y presiona **`Cmd + R`** para ejecutar la aplicación.
   - Para correr la suite de pruebas unitarias (`XCTest`), presiona **`Cmd + U`**.

---

## 📁 Estructura del Proyecto

```text
HardwareQuoteB2B/
├── HardwareQuoteB2B/
│   ├── HardwareQuoteB2BApp.swift                # Punto de entrada SwiftUI + AppDelegate (Firebase & SwiftData)
│   ├── GoogleService-Info.plist                 # Configuración de credenciales de Firebase
│   ├── Models/
│   │   ├── Componente.swift                     # Modelo @Model (SwiftData) y enum CategoriaComponente
│   │   └── Cotizacion.swift                     # Modelo @Model (SwiftData) y cálculo de totales
│   ├── ViewModels/
│   │   └── QuoteBuilderViewModel.swift          # Estado reactivo (@Observable), Watts, precios y REST API
│   ├── Views/
│   │   ├── QuoteBuilderView.swift               # Vista principal SwiftUI del cotizador B2B
│   │   ├── CatalogoHardwareView.swift           # Almacén dinámico de hardware con filtros
│   │   ├── CrearComponenteFormView.swift        # Formulario de alta de stock en tiempo real
│   │   ├── ControlNotasVozView.swift            # Grabadora/reproductora de notas técnicas
│   │   ├── LoginViewController.swift            # Autenticación UIKit con Firebase Auth
│   │   ├── HistorialCotizacionesViewController.swift # Historial UIKit sincronizado con CoreData + RTDB
│   │   ├── ComponentesViewController.swift      # Módulo UIKit demostrativo (@IBOutlet/@IBAction/Segue)
│   │   ├── DetalleComponenteViewController.swift # Detalle técnico UIKit
│   │   └── ComponenteTableViewCell.swift        # Celda personalizada UITableViewCell
│   └── Services/
│       ├── HistorialManager.swift               # Singleton CoreData programático + Firebase RTDB 1:1
│       ├── FirebaseService.swift                # Servicios de Auth, Storage, RTDB y cliente REST URLSession
│       ├── QuotePDFManager.swift                # Motor vectorial UIGraphicsPDFRenderer en directorio temporal
│       └── VoiceNoteManager.swift               # Gestor de audio con AVFoundation y permisos TCC
└── HardwareQuoteB2BTests/
    ├── HardwareQuoteB2BTests.swift              # Suite extendida de pruebas de QA
    └── QuoteBuilderViewModelTests.swift         # Pruebas unitarias de demanda energética, subtotal y margen
```
