// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'


Shader "Custom/MSY/HighShader"
{
//漫反射，高光反射，渐变纹理，多光源叠加，光照衰减
	Properties
	{
	    _Color("Color",Color)=(1,1,1,1)
		_MainTex ("MainTexture", 2D) = "white" {}
		_ShadeTex("ShadeTexture", 2D) = "white" {}
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader
	{
		

		

		Pass
		{
		Tags { 
		"RenderType"="Opaque" 
		"LightMode"="ForwardBase"
		}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			sampler2D _MainTex;
		    float4 _MainTex_ST;
			sampler2D _ShadeTex;
			float4 _ShadeTex_ST;
			fixed4 _Specular;
			fixed4 _Color;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal:NORMAL;

			};

			struct v2f
			{
			float4 pos:SV_POSITION;
			float3 worldNromal:TEXCOORD0;
			float3 worldPos:TEXCOORD1;
			float2 uv:TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				//o.uv =v.texcoord*_MainTex_ST.xy+_MainTex_ST.zw;
				o.worldNromal=UnityObjectToWorldNormal(v.normal);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			fixed3 worldNromal=normalize(i.worldNromal);
			fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
			fixed3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
			fixed3 halfDir=normalize(viewDir+worldLightDir);

			//环境光
			fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT;

			//主纹理采样结果，将来作为自发光颜色的一部分
			fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color;
			
			//半兰伯特部分
			fixed halfLambert=0.5*dot(worldNromal,worldLightDir)+0.5;

			//渐变纹理采样结果
			fixed3 shadeTexResult=tex2D(_ShadeTex,fixed2(halfLambert,halfLambert)).rgb;
			
			//满反射计算结果
			fixed3 diffuse=_LightColor0.rgb * ambient * shadeTexResult * albedo;

			fixed3 specular=_LightColor0.rgb*_Specular.rgb * pow(max(0,dot(worldNromal,halfDir)),_Gloss);

			return fixed4(specular+diffuse+ambient,1.0);
			}
			ENDCG
		}

				Pass
		{
			Tags { "LightMode"="ForwardAdd"}
			Blend One One

			CGPROGRAM
			#pragma multi_compile_fwdadd
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			sampler2D _MainTex;
		    float4 _MainTex_ST;
			sampler2D _ShadeTex;
			float4 _ShadeTex_ST;
			fixed4 _Specular;
			fixed4 _Color;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal:NORMAL;

			};

			struct v2f
			{
			float4 pos:SV_POSITION;
			float3 worldNromal:TEXCOORD0;
			float3 worldPos:TEXCOORD1;
			float2 uv:TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				//o.uv =v.texcoord*_MainTex_ST.xy+_MainTex_ST.zw;
				o.worldNromal=UnityObjectToWorldNormal(v.normal);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			fixed3 worldNromal=normalize(i.worldNromal);

			
			#ifdef USING_DIRECTIONAL_LIGHT
			fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);  //i.worldPos
			#else
			fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz-i.worldPos);
			#endif

			fixed3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
			fixed3 halfDir=normalize(viewDir+worldLightDir);

			//光照衰减
			#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					#if defined (POINT)
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w 
						* tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif

			//主纹理采样结果，将来作为自发光颜色的一部分
			fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color;
			
			//半兰伯特部分
			fixed halfLambert=0.5*dot(worldNromal,worldLightDir)+0.5;

			//渐变纹理采样结果
			fixed3 shadeTexResult=tex2D(_ShadeTex,fixed2(halfLambert,halfLambert)).rgb;
			
			//满反射计算结果
			fixed3 diffuse=_LightColor0.rgb  * shadeTexResult * albedo;

			fixed3 specular=_LightColor0.rgb *_Specular.rgb * pow(max(0,dot(worldNromal,halfDir)),_Gloss);

			return fixed4((specular+diffuse)*atten,1.0);
			}
			ENDCG
		}
	}
}
