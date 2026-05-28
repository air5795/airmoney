# Guía de Preparación para el Lanzamiento en Google Play Store

Este documento contiene las configuraciones técnicas críticas que deben realizarse antes de subir la aplicación **AIRMONEY** de forma oficial a la tienda de aplicaciones Google Play Store. Estas configuraciones garantizan la seguridad de los datos de los usuarios y el correcto funcionamiento del inicio de sesión con Google.

---

## 1. Configuración de Seguridad en Firebase Firestore (Obligatorio)

Por defecto, los proyectos en fase de desarrollo pueden tener reglas de lectura/escritura abiertas. Para producción, debes asegurar que **un usuario solo pueda leer y escribir sus propios datos**.

### Pasos a seguir:
1. Ve a la consola de [Firebase Console](https://console.firebase.google.com/).
2. Selecciona tu proyecto de **AIRMONEY**.
3. En el menú lateral izquierdo, ve a **Build** ➜ **Firestore Database**.
4. Haz clic en la pestaña **Rules** (Reglas) en la parte superior.
5. Reemplaza el editor de reglas con el siguiente bloque de código:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permite que un usuario autenticado acceda únicamente a sus propios datos
    match /usuarios/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

6. Haz clic en el botón **Publish** (Publicar) para guardar y activar los cambios inmediatamente.

---

## 2. Registro del SHA-1 de Producción en Firebase (Obligatorio para Google Sign-In)

Cuando pruebas la aplicación localmente en tu computadora, Flutter la firma con una clave de depuración (*debug keystore*). Sin embargo, al subirla a la Play Store, Google firma la aplicación con una clave oficial de producción (*App Signing Key*), lo cual cambia la huella digital SHA-1. 

Si no registras la huella SHA-1 de producción en Firebase, **el inicio de sesión con Google arrojará un error silencioso y dejará de funcionar para todos los usuarios que la descarguen de la tienda**.

### Pasos a seguir:

#### Paso 2.1: Copiar el SHA-1 de Google Play Console
1. Inicia sesión en la consola de [Google Play Console](https://play.google.com/console/).
2. Selecciona tu aplicación.
3. En el menú lateral izquierdo, desplázate hasta la sección **Configuración** ➜ **Integridad de la aplicación** (en algunas cuentas aparece como **Firma de la aplicación**).
4. En el apartado de **Certificado de firma de clave de aplicación**, localiza la fila **Huella digital del certificado SHA-1**.
5. Copia esa cadena de caracteres hexadecimales de 40 dígitos.

#### Paso 2.2: Registrar el SHA-1 en Firebase
1. Ve a la consola de [Firebase Console](https://console.firebase.google.com/).
2. Selecciona tu proyecto.
3. Haz clic en el icono de **Configuración (engranaje)** al lado de *Descripción general del proyecto* ➜ **Configuración del proyecto**.
4. En la pestaña **General**, desplázate hacia abajo hasta la sección **Tus apps**.
5. Selecciona la aplicación Android de tu proyecto.
6. En la sección *Certificados de huellas digitales SHA*, haz clic en **Agregar huella digital**.
7. Pega la huella SHA-1 que copiaste de la Google Play Console.
8. Haz clic en **Guardar**.

#### Paso 2.3: Actualizar el archivo google-services.json
1. Una vez guardada la nueva huella digital, haz clic en el botón **Descargar google-services.json** que se encuentra justo arriba en esa misma pantalla de Firebase.
2. Copia este nuevo archivo `google-services.json`.
3. Reemplaza el archivo existente en tu proyecto de Flutter en la ruta:
   `android/app/google-services.json`
4. Ejecuta un comando `flutter clean` en tu terminal para limpiar cachés previas.
5. Procede a generar el archivo App Bundle oficial (`flutter build appbundle`) para subirlo a la Play Store de forma segura.
