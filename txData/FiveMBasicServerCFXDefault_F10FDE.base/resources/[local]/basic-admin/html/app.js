(function () {
    'use strict';

    var RESOURCE = 'basic-admin';

    var menu = document.getElementById('menu');
    var pageMain = document.getElementById('page-main');
    var pageVehicles = document.getElementById('page-vehicles');
    var searchInput = document.getElementById('search');
    var vehicleList = document.getElementById('vehicle-list');

    // Fahrzeugkatalog, wie ihn der Server aus der config.lua liefert.
    var catalog = [];

    function post(name, data) {
        return fetch('https://' + RESOURCE + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {})
        }).catch(function () { /* im Browser-Preview ohne NUI ignorieren */ });
    }

    function showPage(page) {
        pageMain.classList.toggle('hidden', page !== 'main');
        pageVehicles.classList.toggle('hidden', page !== 'vehicles');
    }

    function openMenu(vehicles) {
        catalog = vehicles || [];
        searchInput.value = '';
        renderVehicles('');
        showPage('main');
        menu.classList.remove('hidden');
    }

    function closeMenu() {
        menu.classList.add('hidden');
    }

    /** Baut die Fahrzeugliste, gefiltert ueber Label und Modellname. */
    function renderVehicles(filter) {
        var needle = (filter || '').trim().toLowerCase();
        vehicleList.innerHTML = '';
        var hits = 0;

        catalog.forEach(function (group) {
            var matches = (group.vehicles || []).filter(function (v) {
                if (!needle) return true;
                return v.label.toLowerCase().indexOf(needle) !== -1 ||
                       v.model.toLowerCase().indexOf(needle) !== -1;
            });
            if (!matches.length) return;

            var heading = document.createElement('div');
            heading.className = 'category';
            heading.textContent = group.category;
            vehicleList.appendChild(heading);

            matches.forEach(function (v) {
                var row = document.createElement('div');
                row.className = 'vehicle';
                row.dataset.model = v.model;

                var model = document.createElement('span');
                model.className = 'model';
                model.textContent = v.model;

                row.appendChild(model);
                row.appendChild(document.createTextNode(v.label));
                vehicleList.appendChild(row);
                hits++;
            });
        });

        if (!hits) {
            var empty = document.createElement('div');
            empty.className = 'empty';
            empty.textContent = 'Kein Fahrzeug gefunden';
            vehicleList.appendChild(empty);
        }
    }

    // ---- Events ------------------------------------------------------------

    document.getElementById('btn-close').addEventListener('click', function () {
        closeMenu();
        post('close');
    });

    document.getElementById('btn-back').addEventListener('click', function () {
        showPage('main');
    });

    pageMain.addEventListener('click', function (event) {
        var entry = event.target.closest('.entry');
        if (!entry) return;

        if (entry.dataset.action === 'vehicles') {
            showPage('vehicles');
            searchInput.focus();
        } else if (entry.dataset.action === 'teleport') {
            // Menue bleibt offen - der Client schliesst es erst bei Erfolg.
            post('teleportWaypoint');
        }
    });

    vehicleList.addEventListener('click', function (event) {
        var row = event.target.closest('.vehicle');
        if (!row) return;
        closeMenu();
        post('spawnVehicle', { model: row.dataset.model });
    });

    searchInput.addEventListener('input', function () {
        renderVehicles(searchInput.value);
    });

    document.addEventListener('keydown', function (event) {
        if (event.key !== 'Escape') return;
        closeMenu();
        post('close');
    });

    window.addEventListener('message', function (event) {
        var data = event.data || {};
        if (data.action === 'open') {
            openMenu(data.vehicles);
        } else if (data.action === 'close') {
            closeMenu();
        }
    });
}());
