/* ==========================================================
   usuarios.js: botones de usuario, formularios de inicio de
   sesión y registro, y sesión guardada en el navegador.
   Es solo una DEMOSTRACIÓN: no hay servidor, y las contraseñas
   se validan pero NUNCA se guardan.
   ========================================================== */

const CLAVE_SESION = "cinenova_sesion";     // quién tiene la sesión abierta
const CLAVE_USUARIOS = "cinenova_usuarios"; // personas registradas (nombre y correo)

/* Lee un valor guardado en localStorage (la memoria del navegador). Devuelve null si no hay. */
function leerGuardado(clave) {
  try { return JSON.parse(localStorage.getItem(clave)); } catch (e) { return null; }
}
function guardar(clave, valor) {
  try { localStorage.setItem(clave, JSON.stringify(valor)); } catch (e) { /* si falla, seguimos sin guardar */ }
}

/* Inserta en la página las dos ventanas (formularios). Usan la etiqueta <dialog>,
   que el navegador sabe mostrar centrada y con el fondo oscurecido. */
function construirModales() {
  document.body.insertAdjacentHTML("beforeend", `
    <dialog id="modal-login" class="modal" aria-labelledby="t-login">
      <h2 id="t-login">Iniciar sesión</h2>
      <form id="form-login" novalidate>
        <div class="campo"><label for="login-email">Correo electrónico</label>
          <input id="login-email" type="email" autocomplete="email"></div>
        <div class="campo"><label for="login-pass">Contraseña</label>
          <input id="login-pass" type="password" autocomplete="current-password"></div>
        <p class="error" role="alert"></p>
        <div class="fila-botones">
          <button type="button" class="btn-sec" data-cerrar>Cancelar</button>
          <button type="submit" class="btn-prim">Iniciar sesión</button>
        </div>
      </form>
      <p class="cambiar">¿No tienes cuenta? <button type="button" data-abrir="modal-registro">Crear cuenta</button></p>
    </dialog>

    <dialog id="modal-registro" class="modal" aria-labelledby="t-reg">
      <h2 id="t-reg">Crear cuenta</h2>
      <form id="form-registro" novalidate>
        <div class="campo"><label for="reg-nombre">Nombre y apellido</label>
          <input id="reg-nombre" type="text" autocomplete="name"></div>
        <div class="campo"><label for="reg-email">Correo electrónico</label>
          <input id="reg-email" type="email" autocomplete="email"></div>
        <div class="campo"><label for="reg-pass">Contraseña</label>
          <input id="reg-pass" type="password" autocomplete="new-password"></div>
        <div class="campo"><label for="reg-pass2">Confirmar contraseña</label>
          <input id="reg-pass2" type="password" autocomplete="new-password"></div>
        <p class="error" role="alert"></p>
        <div class="fila-botones">
          <button type="button" class="btn-sec" data-cerrar>Cancelar</button>
          <button type="submit" class="btn-prim">Crear cuenta</button>
        </div>
      </form>
      <p class="cambiar">¿Ya tienes cuenta? <button type="button" data-abrir="modal-login">Iniciar sesión</button></p>
    </dialog>`);
}

/* Abre una ventana por su id y cierra la otra. */
function abrirModal(id) {
  document.querySelectorAll(".modal[open]").forEach(m => m.close());
  const modal = document.getElementById(id);
  modal.querySelector("form").reset();
  modal.querySelector(".error").textContent = "";
  modal.showModal();
}

/* Dibuja los botones de la cabecera según haya o no una sesión abierta. */
function pintarSesion() {
  const caja = document.getElementById("acciones-usuario");
  const sesion = leerGuardado(CLAVE_SESION);
  caja.innerHTML = sesion
    ? `<span class="saludo">Hola, ${sesion.nombre}</span><button class="btn-sec" data-accion="salir">Cerrar sesión</button>`
    : `<button class="btn-sec" data-accion="login">Iniciar sesión</button><button class="btn-prim" data-accion="registro">Crear cuenta</button>`;
}

/* Valida un correo de forma sencilla: algo@algo.algo */
function correoValido(correo) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo);
}

/* Inicializa todo lo relacionado con usuarios. Se llama una vez desde main.js. */
function iniciarUsuarios() {
  construirModales();
  pintarSesion();

  // Clics en los botones de la cabecera (se detectan por el atributo data-accion)
  document.getElementById("acciones-usuario").addEventListener("click", e => {
    const accion = e.target.dataset.accion;
    if (accion === "login") abrirModal("modal-login");
    if (accion === "registro") abrirModal("modal-registro");
    if (accion === "salir") { localStorage.removeItem(CLAVE_SESION); pintarSesion(); }
  });

  // Botones "Cancelar", enlaces para cambiar de formulario y clic fuera de la ventana
  document.querySelectorAll(".modal").forEach(modal => {
    modal.addEventListener("click", e => {
      if (e.target === modal || e.target.hasAttribute("data-cerrar")) modal.close();
      if (e.target.dataset.abrir) abrirModal(e.target.dataset.abrir);
    });
  });

  // ENVÍO DEL FORMULARIO DE INICIO DE SESIÓN
  document.getElementById("form-login").addEventListener("submit", e => {
    e.preventDefault(); // evita que el navegador recargue la página
    const email = document.getElementById("login-email").value.trim();
    const pass = document.getElementById("login-pass").value;
    const error = e.target.parentElement.querySelector(".error");
    if (!correoValido(email)) return (error.textContent = "Escribe un correo válido.");
    if (pass.length < 6) return (error.textContent = "La contraseña debe tener al menos 6 caracteres.");
    // Si el correo está registrado usamos su nombre; si no, la parte anterior a la @
    const registrado = (leerGuardado(CLAVE_USUARIOS) || []).find(u => u.email === email);
    guardar(CLAVE_SESION, { nombre: registrado ? registrado.nombre : email.split("@")[0], email });
    document.getElementById("modal-login").close();
    pintarSesion();
  });

  // ENVÍO DEL FORMULARIO DE REGISTRO
  document.getElementById("form-registro").addEventListener("submit", e => {
    e.preventDefault();
    const nombre = document.getElementById("reg-nombre").value.trim();
    const email = document.getElementById("reg-email").value.trim();
    const pass = document.getElementById("reg-pass").value;
    const pass2 = document.getElementById("reg-pass2").value;
    const error = e.target.parentElement.querySelector(".error");
    if (nombre.split(/\s+/).length < 2) return (error.textContent = "Escribe tu nombre y apellido.");
    if (!correoValido(email)) return (error.textContent = "Escribe un correo válido.");
    if (pass.length < 6) return (error.textContent = "La contraseña debe tener al menos 6 caracteres.");
    if (pass !== pass2) return (error.textContent = "Las contraseñas no coinciden.");
    const usuarios = leerGuardado(CLAVE_USUARIOS) || [];
    if (usuarios.some(u => u.email === email)) return (error.textContent = "Ese correo ya tiene una cuenta.");
    usuarios.push({ nombre, email }); // la contraseña no se guarda
    guardar(CLAVE_USUARIOS, usuarios);
    guardar(CLAVE_SESION, { nombre, email });
    document.getElementById("modal-registro").close();
    pintarSesion();
  });
}
