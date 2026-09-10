// gerador_pp.dcl — Diálogo DCL para o gerador de porta-palete
// Compatível com AutoCAD 2013 ou superior

gerador_pp : dialog {
  label = "Gerador de Layout - Porta-Palete";
  width = 68;

  : row {
    // ===================== COLUNA ESQUERDA =====================
    : column {
      fixed_width = true;
      width = 32;

      // --- Box Galpão ---
      : boxed_column {
        label = "Galpão";

        : row {
          : edit_box {
            label = "Comprimento (mm):";
            key   = "comprimento";
            edit_width = 8;
            value = "25000";
          }
        }
        : row {
          : edit_box {
            label = "Largura (mm):";
            key   = "largura";
            edit_width = 8;
            value = "20000";
          }
        }
        : row {
          : text { label = "Tipo de rack:"; }
        }
        : row {
          : radio_button {
            label = "Simples";
            key   = "tipo_s";
            value = "0";
          }
          : radio_button {
            label = "Duplo (back-to-back)";
            key   = "tipo_d";
            value = "1";
          }
        }
      } // fim boxed_column Galpão

      // --- Box Coluna e Montante (A-B) ---
      : boxed_column {
        label = "Coluna e Montante (A - B)";

        : row {
          : edit_box {
            label = "Cota A - Profundidade montante (mm):";
            key   = "cota_a";
            edit_width = 8;
            value = "1000";
          }
        }
        : row {
          : popup_list {
            label = "Cota B - Largura coluna:";
            key   = "b_list";
            edit_width = 10;
            value = "0";
            list  = "80 mm\n101 mm\n122 mm";
          }
        }
        : row {
          : edit_box {
            label = "Espessura da chapa (mm):";
            key   = "esp";
            edit_width = 8;
            value = "2.25";
          }
        }
      } // fim boxed_column Coluna e Montante

      // --- Box Longarina (C) ---
      : boxed_column {
        label = "Longarina (C)";

        : row {
          : edit_box {
            label = "Cota C - Comp. longarina/vão (mm):";
            key   = "cota_c";
            edit_width = 8;
            value = "2300";
          }
        }
        : row {
          : edit_box {
            label = "Altura do perfil longarina (mm):";
            key   = "alt_long";
            edit_width = 8;
            value = "93";
          }
        }
      } // fim boxed_column Longarina

    } // fim coluna esquerda

    // ===================== COLUNA DIREITA =====================
    : column {
      fixed_width = true;
      width = 32;

      // --- Box Posicionamento (D-E-F-G) ---
      : boxed_column {
        label = "Posicionamento (D - E - F - G)";

        : row {
          : edit_box {
            label = "Cota D - Dist. entre fileiras back-to-back (mm):";
            key   = "cota_d";
            edit_width = 8;
            value = "0";
          }
        }
        : row {
          : edit_box {
            label = "Cota E - Fundo montante à parede (mm):";
            key   = "cota_e";
            edit_width = 8;
            value = "500";
          }
        }
        : row {
          : edit_box {
            label = "Cota F - Lateral montante à parede (mm):";
            key   = "cota_f";
            edit_width = 8;
            value = "500";
          }
        }
        : row {
          : edit_box {
            label = "Cota G - Largura do corredor (mm):";
            key   = "cota_g";
            edit_width = 8;
            value = "3500";
          }
        }
      } // fim boxed_column Posicionamento

      // --- Box Pilares (H-I) ---
      : boxed_column {
        label = "Pilares Estruturais (H - I)";

        : row {
          : edit_box {
            label = "Cota H - Dist. X centro pilar / parede (mm):";
            key   = "cota_h";
            edit_width = 8;
            value = "2300";
          }
        }
        : row {
          : edit_box {
            label = "Cota I - Dist. Y centro pilar / parede (mm):";
            key   = "cota_i";
            edit_width = 8;
            value = "2500";
          }
        }
      } // fim boxed_column Pilares

      // --- Box Níveis de Palete ---
      : boxed_column {
        label = "Níveis de Palete";

        : row {
          : popup_list {
            label = "Número de níveis:";
            key   = "n_niv";
            edit_width = 6;
            value = "3";
            list  = "1\n2\n3\n4\n5\n6\n7\n8";
          }
        }
        : row {
          : edit_box {
            label = "Altura 1º nível - H1 (mm):";
            key   = "h1";
            edit_width = 8;
            value = "1000";
          }
        }
        : row {
          : edit_box {
            label = "Passo entre níveis (mm):";
            key   = "passo";
            edit_width = 8;
            value = "1000";
          }
        }
      } // fim boxed_column Níveis

    } // fim coluna direita

  } // fim row principal

  // --- Mensagem de erro ---
  : errtile {
    key    = "errtile";
    width  = 64;
  }

  // --- Botões OK / Cancelar ---
  ok_cancel;

} // fim dialog gerador_pp
