#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da cor de cada vértice, definidas em "shader_vertex.glsl" e
// "main.cpp".
in vec4 position_world;
in vec4 normal;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define SPHERE 0
#define BUNNY  1
#define PLANE  2
uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0;
uniform sampler2D TextureImage1;
uniform sampler2D TextureImage2;
uniform sampler2D TextureImage3;
uniform sampler2D TextureImage4;
uniform sampler2D TextureImage5;
uniform sampler2D TextureImage6;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;
    vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;

    if ( object_id == SPHERE )
    {
        // PREENCHA AQUI as coordenadas de textura da esfera, computadas com
        // projeção esférica EM COORDENADAS DO MODELO. Utilize como referência
        // o slide 139 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        // A esfera que define a projeção deve estar centrada na posição
        // "bbox_center" definida abaixo.

        // Você deve utilizar:
        //   função 'length( )' : comprimento Euclidiano de um vetor
        //   função 'atan( , )' : arcotangente. Veja https://en.wikipedia.org/wiki/Atan2.
        //   função 'asin( )'   : seno inverso.
        //   constante M_PI
        //   variável position_model

        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;
        vec4 p=position_model-bbox_center;

        float px=position_model.x;
        float py=position_model.y;
        float pz=position_model.z;

        float ro=length(p);
        float theta=atan(px, pz);
        float phi=asin(py/ro);

        U = (theta+M_PI)/(2*M_PI);
        V = (phi+M_PI_2)/M_PI;
        vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
    }
    else if ( object_id == BUNNY )
    {
        // PREENCHA AQUI as coordenadas de textura do coelho, computadas com
        // projeção planar XY em COORDENADAS DO MODELO. Utilize como referência
        // o slide 106 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        float minx = bbox_min.x;
        float maxx = bbox_max.x;

        float miny = bbox_min.y;
        float maxy = bbox_max.y;

        float minz = bbox_min.z;
        float maxz = bbox_max.z;

        // Utilize as variáveis min*/max* definidas acima para normalizar as
        // coordenadas de textura U e V dentro do intervalo [0,1]. Veja 149
        // do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        U=(position_model.x-minx)/(maxx-minx);
        V=(position_model.y-miny)/(maxy-miny);
        Kd0 = texture(TextureImage0, vec2(U,V)).rgb;

    }
    else if ( object_id == PLANE )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;
        Kd0 = texture(TextureImage6, vec2(U,V)).rgb;
    }


    // Obtemos a refletância difusa a partir da leitura da imagem TextureImage0
  // vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;

    // Equação de Iluminação
    float lambert = max(0,dot(n,l));

    color = Kd0 * (lambert + 0.01);


    /*

    if ( object_id == COW ) //implementa-se os modelos de iluminação
    {

        // Propriedades espectrais da vaca
        vec3 Kd = vec3(0.08,0.4,0.8);
        vec3 Ks = vec3(0.8,0.8,0.8);
        vec3 Ka = vec3(0.04,0.2,0.4);
        float q = 32.0;

        // Espectro da fonte de iluminação
        vec3 I = vec3(1.0,1.0,1.0);
        // Espectro da luz ambiente
        vec3 Ia = vec3(0.2, 0.2, 0.2);

        // Vetor que define o sentido da reflexão especular ideal.
        vec4 r = -l + 2 * n * dot(l,n);

        // Termo difuso utilizando a lei dos cossenos de Lambert
        vec3 lambert_diffuse_term = Kd * I * max(0, dot(n,l));
        // Termo ambiente
        vec3 ambient_term = Ka * Ia;
        // Termo especular utilizando o modelo de iluminação de Blinn-Phong
        vec3 blinnphong_specular_term  = Ks * I * pow(max(0, dot(n,h)), q);

        // Cor final do fragmento calculada com uma combinação dos termos difuso,
        // especular, e ambiente.
        color = lambert_diffuse_term + ambient_term + blinnphong_specular_term;
    }
    */


    /*
    //Modelos de Iluminação
    if ( object_id == VACA )
    {

        // Propriedades espectrais da vaca
        vec3 Kd = vec3(0.08,0.4,0.8);
        vec3 Ks = vec3(0.8,0.8,0.8);
     ***   vec3 Ka = vec3(0.04,0.2,0.4);  //Ka = Kd/2.0f;
        float q = 32.0;

        // Espectro da fonte de iluminação
        vec3 I = vec3(1.0,1.0,1.0);
        // Espectro da luz ambiente
        vec3 Ia = vec3(0.2, 0.2, 0.2);

        // Vetor que define o sentido da reflexão especular ideal.
        vec4 r = -l + 2 * n * dot(l,n);

        // Termo difuso utilizando a lei dos cossenos de Lambert
        vec3 lambert_diffuse_term = Kd * I * max(0, dot(n,l));
        // Termo ambiente
        vec3 ambient_term = Ka * Ia;


      *** // Termo especular utilizando o modelo de iluminação de Blinn-Phong
      ***  vec3 blinnphong_specular_term  = Ks * I * pow(max(0, dot(n,h)), q);

        //
    // Termo especular utilizando o modelo de iluminação de Phong
    //vec3 phong_specular_term  = Ks * I * pow(dot(r, l), q);


        // Cor final do fragmento calculada com uma combinação dos termos difuso,
        // especular, e ambiente.
        color = lambert_diffuse_term + ambient_term + blinnphong_specular_term;
    }
    */




    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    color = pow(color, vec3(1.0,1.0,1.0)/2.2);
}
