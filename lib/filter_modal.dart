import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
class FilterModal {
  static void show({
    required BuildContext context,
    required String currentFilter,
    required String currentDate,
    required String currentType,
    required Function(String, String, String) onApply,
  }) {
    String tempFilter = currentFilter;
    String tempDate = currentDate;
    String tempType = currentType;

    final localidades = [ "Todos","Norte", "Occidente", "Oriente", "Sur", "Noroccidente", "Nororiente", "Suroriente", "Suroccidente" ];
    final fechas = [
      "Todas",
      "2025-03-01",
      "2025-03-05",
      "2025-03-10",
      "2025-03-15",
      "2025-03-20",
    ];
    final tipos = ["Todos", "Gastrobar","Discotecas","Cultural","Deportivo"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: EdgeInsets.fromLTRB(
                    25, 30, 25, MediaQuery.of(context).viewInsets.bottom + 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrar Eventos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Filtro de Localidad con scroll horizontal
                    _buildModernFilterSection(
                      title: "Localidad",
                      options: localidades,
                      currentSelection: tempFilter,
                      onSelect: (value) {
                        setModalState(() {
                          tempFilter = value;
                        });
                      },
                    ),
                    SizedBox(height: 25),

                    // Filtro de Fecha con scroll horizontal
                    _buildModernFilterSection(
                      title: "Fecha",
                      options: fechas,
                      currentSelection: tempDate,
                      onSelect: (value) {
                        setModalState(() {
                          tempDate = value;
                        });
                      },
                    ),
                    SizedBox(height: 25),

                    // Filtro de Tipo
                    _buildModernFilterSection(
                      title: "Tipo de Evento",
                      options: tipos,
                      currentSelection: tempType,
                      onSelect: (value) {
                        setModalState(() {
                          tempType = value;
                        });
                      },
                    ),
                    SizedBox(height: 30),

                    // Botón de aplicar
                    Row(
                      children: [
                        // Botón Reset
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempFilter = "Todos";
                                tempDate = "Todas";
                                tempType = "Todos";
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: BorderSide(color: Colors.black),
                            ),
                            child: Text(
                              'Reiniciar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        // Botón Aplicar
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onApply(tempFilter, tempDate, tempType);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Aplicar Filtros',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Método auxiliar para construir secciones de filtro
  static Widget _buildModernFilterSection({
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              bool isSelected = currentSelection == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) => onSelect(option),
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  labelPadding: EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}