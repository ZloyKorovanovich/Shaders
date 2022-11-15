Shader "WaterSimulation/WaterUrp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


			struct DisplacementOut
			{
				float3 position;
				float3 normal;
			};

			DisplacementOut GerstnerWave(float3 position, float ampl, float speed, float time, float length)
			{

				DisplacementOut output;
				output.position = position;
				float cof = 2 * UNITY_PI / length;
				float func = cof * (output.position.x - speed * time);
				output.position.x += ampl * cos(func);
				output.position.y = ampl * sin(func);

				float3 tangent = normalize(float3(1 - cof * ampl * sin(func), cof * ampl * cos(func), 0));
				output.normal = float3(-tangent.y, tangent.x, 0);
				
				return output;
			}


            sampler2D _MainTex;
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
