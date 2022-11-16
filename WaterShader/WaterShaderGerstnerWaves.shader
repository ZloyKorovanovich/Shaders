Shader "WaterSimulation/WaterUrp"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
		
	_Amplitude("Amplitude", float) = 0.5
	_Speed("Speed", float) = 1
	_Length("Length", float) = 1
			
	_Octaves("Octaves", int) = 1

	_NoiseScale("NoiseScale", int) = 5
	_NoiseStrength("NoiseStrength", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True"}
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
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


	    struct Gerstner
	    {
		float ampl;
		float speed;
		float length;
	    };

	    struct DisplacementOut
	    {
		float4 position;
		float3 normal;
	    };



	    float2 GradientNoise_dir(float2 p)
	    {
		p = p % 289;
		float x = (34 * p.x + 1) * p.x % 289 + p.y;
	        x = (34 * x + 1) * x % 289;
		x = frac(x / 41) * 2 - 1;
		return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
	    }

	    float GradientNoise(float2 p)
	    {
		float2 ip = floor(p);
		float2 fp = frac(p);
		float d00 = dot(GradientNoise_dir(ip), fp);
		float d01 = dot(GradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
		float d10 = dot(GradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
		float d11 = dot(GradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
		fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
		return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
	    }

	    float GradientNoise_float(float2 UV, float Scale)
	    {
		return GradientNoise(UV * Scale) + 0.5;
	    }


	    DisplacementOut GerstnerWave(float4 position, float ampl, float speed, float length, float time)
	    {

		DisplacementOut output;
		output.position = position;
		float cof = 2 * UNITY_PI / length;
		float func = cof * (position.x - speed * time);
		output.position.x += ampl * cos(func);
		output.position.y = ampl * sin(func);
		
		float3 tangent = normalize(float3(1 - cof * ampl * sin(func), cof * ampl * cos(func), 0));
		output.normal = float3(-tangent.y, tangent.x, 0);
				
		return output;
	    }

            sampler2D _MainTex;
            float4 _MainTex_ST;
	    float _Amplitude, _Speed, _Length, _NoiseStrength;
	    int _NoiseScale;


            v2f vert (appdata v)
            {
				float c = GradientNoise_float(v.uv, _NoiseScale) * sin(_Time.x);
				DisplacementOut dsO = GerstnerWave(v.vertex, lerp(_Amplitude, c, _NoiseStrength), _Speed, _Length, _Time.y);
				v.vertex = dsO.position;
				v.normal = dsO.normal;

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
