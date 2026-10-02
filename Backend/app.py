from flask import Flask, request, jsonify
from flask_cors import CORS

from google import genai
from google.genai import types

from pydantic import BaseModel


# =========================================================
# CONFIGURACIÓN DE FLASK
# =========================================================

app = Flask(__name__)

CORS(app)


# =========================================================
# 🔑 API KEY DE GEMINI
# =========================================================
# PON AQUÍ TU NUEVA API KEY
# =========================================================

GEMINI_API_KEY = "PON_AQUI_TU_API_KEY"


# Crear cliente de Gemini

client = genai.Client(
    api_key=GEMINI_API_KEY
)


# =========================================================
# MODELO DE RECETA
# =========================================================

class RecetaIA(BaseModel):

    titulo: str

    tiempo: str

    ingredientes: list[str]

    pasos: list[str]


# =========================================================
# DATOS EN MEMORIA
# =========================================================

ingredientes_sugeridos = [

    "Arroz",
    "Huevo",
    "Tomate",
    "Cebolla",
    "Papa",
    "Pollo",
    "Zanahoria",
    "Leche",
    "Queso",
    "Pan",
    "Atún",
    "Pasta",
    "Ajo",
    "Lentejas",
    "Frijoles"

]


# Historial temporal de recetas

historial = []


# Contador para los IDs

contador_id = 1


# =========================================================
# GET
# INGREDIENTES SUGERIDOS
# =========================================================

@app.route(
    "/api/ingredientes/sugeridos",
    methods=["GET"]
)
def ingredientes_sugeridos_endpoint():

    return jsonify({

        "success": True,

        "ingredientes": ingredientes_sugeridos

    }), 200


# =========================================================
# POST
# GENERAR RECETA
# =========================================================

@app.route(
    "/api/receta/generar",
    methods=["POST"]
)
def generar_receta():

    global contador_id

    try:

        # -------------------------------------------------
        # RECIBIR JSON
        # -------------------------------------------------

        data = request.get_json()


        # -------------------------------------------------
        # VALIDAR JSON
        # -------------------------------------------------

        if not data:

            return jsonify({

                "success": False,

                "error": "Debe enviar un JSON"

            }), 400


        # -------------------------------------------------
        # OBTENER INGREDIENTES
        # -------------------------------------------------

        ingredientes = data.get(
            "ingredientes"
        )


        # -------------------------------------------------
        # VALIDAR INGREDIENTES
        # -------------------------------------------------

        if not ingredientes:

            return jsonify({

                "success": False,

                "error":
                    "Debe enviar al menos un ingrediente"

            }), 400


        if not isinstance(
            ingredientes,
            list
        ):

            return jsonify({

                "success": False,

                "error":
                    "ingredientes debe ser una lista"

            }), 400


        # -------------------------------------------------
        # CONVERTIR LISTA A TEXTO
        # -------------------------------------------------

        lista_ingredientes = ", ".join(
            ingredientes
        )


        # =================================================
        # PROMPT ENGINEERING
        # =================================================

        prompt = f"""

Eres EcoEat, un chef virtual especializado
en reducir el desperdicio de alimentos.

El usuario tiene los siguientes ingredientes:

{lista_ingredientes}


Tu tarea es crear UNA receta utilizando
principalmente esos ingredientes.


REGLAS:

1. La receta debe ser sencilla.

2. Debe poder prepararse en casa.

3. Debes aprovechar principalmente
   los ingredientes proporcionados.

4. No inventes ingredientes principales.

5. Puedes utilizar ingredientes básicos como:

   - Sal
   - Aceite
   - Agua
   - Pimienta
   - Especias


La respuesta debe contener:

- titulo
- tiempo
- ingredientes
- pasos


No escribas explicaciones adicionales.
Devuelve únicamente la información solicitada
en formato JSON.

"""


        # =================================================
        # LLAMAR A GEMINI
        # =================================================

        response = client.models.generate_content(

            model="gemini-3.8-flash",

            contents=prompt,

            config=types.GenerateContentConfig(

                response_mime_type="application/json",

                response_schema=RecetaIA

            )

        )


        # =================================================
        # CONVERTIR RESPUESTA DE GEMINI
        # A OBJETO PYDANTIC
        # =================================================

        receta = RecetaIA.model_validate_json(
            response.text
        )


        # =================================================
        # CREAR RECETA PARA EL HISTORIAL
        # =================================================

        nueva_receta = {

            "id": contador_id,

            "titulo": receta.titulo,

            "tiempo": receta.tiempo,

            "ingredientes":
                receta.ingredientes,

            "pasos":
                receta.pasos,

            "favorito": False

        }


        # =================================================
        # GUARDAR EN MEMORIA
        # =================================================

        historial.append(
            nueva_receta
        )


        contador_id += 1


        # =================================================
        # RESPUESTA
        # =================================================

        return jsonify({

            "success": True,

            "receta": nueva_receta

        }), 201


    except Exception as e:

        print(
            "\n========== ERROR GEMINI =========="
        )

        print(str(e))

        print(
            "==================================\n"
        )


        return jsonify({

            "success": False,

            "error":
                "No fue posible generar la receta",

            "detalle":
                str(e)

        }), 500


# =========================================================
# PUT
# ACTUALIZAR FAVORITO
# =========================================================

@app.route(
    "/api/historial/favorito",
    methods=["PUT"]
)
def actualizar_favorito():

    try:

        # -------------------------------------------------
        # RECIBIR JSON
        # -------------------------------------------------

        data = request.get_json()


        if not data:

            return jsonify({

                "success": False,

                "error":
                    "Debe enviar un JSON"

            }), 400


        # -------------------------------------------------
        # OBTENER DATOS
        # -------------------------------------------------

        receta_id = data.get(
            "id"
        )

        favorito = data.get(
            "favorito"
        )


        # -------------------------------------------------
        # VALIDAR
        # -------------------------------------------------

        if receta_id is None:

            return jsonify({

                "success": False,

                "error":
                    "Debe enviar el id"

            }), 400


        if favorito is None:

            return jsonify({

                "success": False,

                "error":
                    "Debe enviar favorito"

            }), 400


        # -------------------------------------------------
        # BUSCAR RECETA
        # -------------------------------------------------

        for receta in historial:

            if receta["id"] == receta_id:

                receta["favorito"] = favorito


                return jsonify({

                    "success": True,

                    "mensaje":
                        "Favorito actualizado",

                    "receta":
                        receta

                }), 200


        # -------------------------------------------------
        # NO ENCONTRADA
        # -------------------------------------------------

        return jsonify({

            "success": False,

            "error":
                "Receta no encontrada"

        }), 404


    except Exception as e:

        return jsonify({

            "success": False,

            "error":
                str(e)

        }), 500


# =========================================================
# DELETE
# ELIMINAR RECETA
# =========================================================

@app.route(
    "/api/historial/<int:receta_id>",
    methods=["DELETE"]
)
def eliminar_receta(
    receta_id
):

    # -----------------------------------------------------
    # BUSCAR RECETA
    # -----------------------------------------------------

    for receta in historial:

        if receta["id"] == receta_id:

            historial.remove(
                receta
            )


            return jsonify({

                "success": True,

                "mensaje":
                    "Receta eliminada correctamente",

                "id":
                    receta_id

            }), 200


    # -----------------------------------------------------
    # NO ENCONTRADA
    # -----------------------------------------------------

    return jsonify({

        "success": False,

        "error":
            "Receta no encontrada"

    }), 404


# =========================================================
# GET
# VER HISTORIAL
# =========================================================
# Este endpoint NO es obligatorio para el parcial,
# pero nos sirve para revisar lo que hay en memoria.
# =========================================================

@app.route(
    "/api/historial",
    methods=["GET"]
)
def obtener_historial():

    return jsonify({

        "success": True,

        "total":
            len(historial),

        "historial":
            historial

    }), 200


# =========================================================
# ENDPOINT PRINCIPAL
# =========================================================

@app.route(
    "/",
    methods=["GET"]
)
def inicio():

    return jsonify({

        "mensaje":
            "EcoEat API funcionando",

        "version":
            "1.0",

        "estado":
            "OK"

    }), 200


# =========================================================
# EJECUTAR SERVIDOR
# =========================================================

if __name__ == "__main__":

    print()
    print(
        "======================================"
    )
    print(
        "          ECOEAT API"
    )
    print(
        "======================================"
    )
    print(
        "Servidor iniciado"
    )
    print(
        "http://localhost:5000"
    )
    print(
        "======================================"
    )
    print()

    app.run(

        host="0.0.0.0",

        port=5000,

        debug=True

    )