/* ==========================================================
   navegacion.js: cabecera, barra de navegación, menús
   desplegables (Cines, Ciudad, Películas) y buscador.
   ========================================================== */

// Ciudades y cines inventados del complejo
const CIUDADES = ["Buenos Aires", "Córdoba", "Rosario", "Mendoza"];
const CINES = [
  { nombre: "CineNova Centro", ciudad: "Buenos Aires", direccion: "Av. Corrientes 1450" },
  { nombre: "CineNova Paseo Oeste", ciudad: "Buenos Aires", direccion: "Paseo Oeste, Ramos Mejía" },
  { nombre: "CineNova Shopping Norte", ciudad: "Córdoba", direccion: "Av. Rafael Núñez 4600" },
  { nombre: "CineNova Plaza Sur", ciudad: "Rosario", direccion: "Bv. Oroño 2100" },
  { nombre: "CineNova Andes", ciudad: "Mendoza", direccion: "Av. San Martín 980" }
];

// Estado compartido: lo que el usuario eligió (ciudad y cine se recuerdan entre páginas)
const seleccion = { ciudad: leerGuardado("cinenova_ciudad") || "", cine: leerGuardado("cinenova_cine") || "" };
// Filtros activos de la cartelera (género y texto de búsqueda)
const filtros = { genero: "", texto: "" };
// main.js asigna aquí la función que vuelve a dibujar la cartelera cuando cambian los filtros
let alCambiarFiltros = null;
let BASE = "";    // ruta hacia la raíz del proyecto ("" o "../")
let PAGINA = "";  // "inicio" o "pelicula"

/* Dibuja la cabecera: apartado de usuario arriba y la barra de navegación debajo.
   Los menús están vacíos; los llenan las funciones pintar... de más abajo. */
function construirCabecera(base) {
  document.getElementById("cabecera").innerHTML = `
    <div class="barra-usuario">
      <a class="logo" href="${base}index.html">CineNova</a>
      <div class="acciones-usuario" id="acciones-usuario"></div>
    </div>
    <nav class="barra-nav" aria-label="Navegación principal">
      <div class="item-menu">
        <button class="btn-menu" aria-expanded="false" aria-controls="menu-cines">Cines <span class="etq" id="etq-cine"></span></button>
        <ul class="desplegable" id="menu-cines"></ul>
      </div>
      <div class="item-menu">
        <button class="btn-menu" aria-expanded="false" aria-controls="menu-ciudades">Ciudad <span class="etq" id="etq-ciudad"></span></button>
        <ul class="desplegable" id="menu-ciudades"></ul>
      </div>
      <div class="item-menu">
        <button class="btn-menu" aria-expanded="false" aria-controls="menu-generos">Películas <span class="etq" id="etq-genero"></span></button>
        <ul class="desplegable" id="menu-generos"></ul>
      </div>
      <form class="buscador" id="form-buscar" role="search">
        <input type="search" id="campo-buscar" placeholder="Buscar película" aria-label="Buscar película">
        <button type="submit" class="btn-sec">Buscar</button>
      </form>
    </nav>`;
}

/* Cierra todos los menús desplegables (quita la clase "abierto"). */
function cerrarMenus() {
  document.querySelectorAll(".item-menu.abierto").forEach(item => {
    item.classList.remove("abierto");
    item.querySelector(".btn-menu").setAttribute("aria-expanded", "false");
  });
}

/* Crea una opción <li><button> para un menú. "detalle" es un texto pequeño opcional. */
function crearOpcion(texto, detalle, activa, alElegir) {
  const li = document.createElement("li");
  const boton = document.createElement("button");
  boton.className = "opcion" + (activa ? " activa" : "");
  boton.innerHTML = texto + (detalle ? `<small>${detalle}</small>` : "");
  boton.addEventListener("click", () => { alElegir(); cerrarMenus(); });
  li.appendChild(boton);
  return li;
}

/* Muestra en los botones de la barra lo que se eligió (ciudad, cine, género). */
function actualizarEtiquetas() {
  document.getElementById("etq-cine").textContent = seleccion.cine;
  document.getElementById("etq-ciudad").textContent = seleccion.ciudad;
  document.getElementById("etq-genero").textContent = filtros.genero;
}

/* MENÚ CINES: si hay una ciudad elegida, solo muestra los cines de esa ciudad. */
function pintarCines() {
  const menu = document.getElementById("menu-cines");
  menu.innerHTML = "";
  const lista = CINES.filter(c => !seleccion.ciudad || c.ciudad === seleccion.ciudad);
  menu.appendChild(crearOpcion("Todos los cines", "", !seleccion.cine, () => elegirCine("")));
  lista.forEach(c => menu.appendChild(
    crearOpcion(c.nombre, `${c.direccion}, ${c.ciudad}`, seleccion.cine === c.nombre, () => elegirCine(c.nombre))
  ));
}
function elegirCine(nombre) {
  seleccion.cine = nombre;
  guardar("cinenova_cine", nombre);
  pintarCines(); actualizarEtiquetas();
}

/* MENÚ CIUDAD: al elegir una ciudad se actualiza la lista de cines. */
function pintarCiudades() {
  const menu = document.getElementById("menu-ciudades");
  menu.innerHTML = "";
  menu.appendChild(crearOpcion("Todas las ciudades", "", !seleccion.ciudad, () => elegirCiudad("")));
  CIUDADES.forEach(c => menu.appendChild(crearOpcion(c, "", seleccion.ciudad === c, () => elegirCiudad(c))));
}
function elegirCiudad(ciudad) {
  seleccion.ciudad = ciudad;
  guardar("cinenova_ciudad", ciudad);
  // Si el cine elegido no pertenece a la nueva ciudad, se quita la selección de cine
  const cine = CINES.find(c => c.nombre === seleccion.cine);
  if (ciudad && cine && cine.ciudad !== ciudad) { seleccion.cine = ""; guardar("cinenova_cine", ""); }
  pintarCiudades(); pintarCines(); actualizarEtiquetas();
}

/* MENÚ PELÍCULAS (géneros): en el inicio filtra la cartelera al instante;
   desde la ficha de una película lleva al inicio con el filtro aplicado. */
function pintarGeneros() {
  const menu = document.getElementById("menu-generos");
  menu.innerHTML = "";
  menu.appendChild(crearOpcion("Todos los géneros", "", !filtros.genero, () => elegirGenero("")));
  GENEROS.forEach(g => menu.appendChild(crearOpcion(g, "", filtros.genero === g, () => elegirGenero(g))));
}
function elegirGenero(genero) {
  if (PAGINA !== "inicio") { location.href = `${BASE}index.html?genero=${encodeURIComponent(genero)}#cartelera`; return; }
  filtros.genero = genero;
  pintarGeneros(); actualizarEtiquetas();
  alCambiarFiltros();
}

/* BUSCADOR: en el inicio filtra mientras se escribe; en la ficha, al enviar,
   lleva al inicio con la búsqueda. */
function iniciarBuscador() {
  const campo = document.getElementById("campo-buscar");
  campo.addEventListener("input", () => {
    if (PAGINA !== "inicio") return;
    filtros.texto = campo.value;
    alCambiarFiltros();
  });
  document.getElementById("form-buscar").addEventListener("submit", e => {
    e.preventDefault();
    if (PAGINA === "inicio") { filtros.texto = campo.value; alCambiarFiltros(); }
    else location.href = `${BASE}index.html?buscar=${encodeURIComponent(campo.value)}#cartelera`;
  });
}

/* Quita género y texto de búsqueda y vuelve a mostrar toda la cartelera. */
function limpiarFiltros() {
  filtros.genero = ""; filtros.texto = "";
  document.getElementById("campo-buscar").value = "";
  pintarGeneros(); actualizarEtiquetas();
  alCambiarFiltros();
}

/* Activa la apertura y cierre de los menús y llena sus opciones. */
function iniciarMenus(base, pagina) {
  BASE = base; PAGINA = pagina;
  document.querySelectorAll(".item-menu").forEach(item => {
    const boton = item.querySelector(".btn-menu");
    boton.addEventListener("click", () => {
      const estabaAbierto = item.classList.contains("abierto");
      cerrarMenus(); // solo un menú abierto a la vez
      if (!estabaAbierto) { item.classList.add("abierto"); boton.setAttribute("aria-expanded", "true"); }
    });
  });
  // Clic fuera de los menús o tecla Escape: se cierran
  document.addEventListener("click", e => { if (!e.target.closest(".item-menu")) cerrarMenus(); });
  document.addEventListener("keydown", e => { if (e.key === "Escape") cerrarMenus(); });
  pintarCines(); pintarCiudades(); pintarGeneros(); iniciarBuscador(); actualizarEtiquetas();
}
