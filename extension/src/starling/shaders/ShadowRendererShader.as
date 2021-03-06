/**
 * User: booster
 * Date: 17/12/13
 * Time: 9:48
 */
package starling.shaders {
import com.barliesque.agal.EasierAGAL;
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IField;
import com.barliesque.agal.IRegister;
import com.barliesque.agal.TextureFlag;
import com.barliesque.shaders.macro.Utils;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import starling.shaders.ITextureShader;

public class ShadowRendererShader extends EasierAGAL implements ITextureShader{
    private static var _constants:Vector.<Number> = new <Number>[0.0, 0.5, 1.0, 2.0];

    private var _useVertexUVRange:Boolean;

    private var _uv:Vector.<Number>         = new <Number>[0.0, 1.0, 0.0, 1.0];
    private var _colors:Vector.<Number>     = new <Number>[1.0, 1.0, 1.0, 0.0];
    private var _pixelSize:Vector.<Number>  = new <Number>[0.0, 0.0, 0.0, 0.0];

    public function ShadowRendererShader(useVertexUVRange:Boolean = true) {
        _useVertexUVRange = useVertexUVRange;
    }

    public function get minU():Number { return _uv[0]; }
    public function set minU(value:Number):void { _uv[0] = value; }

    public function get maxU():Number { return _uv[1]; }
    public function set maxU(value:Number):void { _uv[1] = value; }

    public function get minV():Number { return _uv[2]; }
    public function set minV(value:Number):void { _uv[2] = value; }

    public function get maxV():Number { return _uv[3]; }
    public function set maxV(value:Number):void { _uv[3] = value; }

    public function get color():int {
        var r:int = Math.round(_colors[0] * 255);
        var g:int = Math.round(_colors[1] * 255);
        var b:int = Math.round(_colors[2] * 255);

        return (r << 16) + (g << 8) + b;
    }

    public function set color(value:int):void {
        var r:int = ((value & 0xFF0000) >> 16);
        var g:int = ((value & 0x00FF00) >> 8);
        var b:int = (value & 0x0000FF);

        _colors[0] = r / 255.0;
        _colors[1] = g / 255.0;
        _colors[2] = b / 255.0;
    }

    public function get pixelWidth():Number { return _pixelSize[0]; }
    public function set pixelWidth(value:Number):void {
        if(value == _pixelSize[0])
            return;

        _pixelSize[0] = value;
        _pixelSize[2] = value / 2;
    }

    public function get pixelHeight():Number { return _pixelSize[1]; }
    public function set pixelHeight(value:Number):void {
        if(value == _pixelSize[1])
            return;

        _pixelSize[1] = value;
        _pixelSize[3] = value / 2;
    }

    public function get useVertexUVRange():Boolean { return _useVertexUVRange; }
    public function set useVertexUVRange(value:Boolean):void { _useVertexUVRange = value; }

    public function activate(context:Context3D):void {
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _constants);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _colors);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _pixelSize);

        if(_useVertexUVRange)
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, _uv);
    }

    public function deactivate(context:Context3D):void { }

    override protected function _vertexShader():void {
        comment("Apply a 4x4 matrix to transform vertices to clip-space");
        multiply4x4(OUTPUT, ATTRIBUTE[0], CONST[0]);

        comment("Pass uv coordinates to fragment shader");
        move(VARYING[0], ATTRIBUTE[1]);

        if(_useVertexUVRange) {
            comment("Pass minU, maxU, minV, maxV to fragment shader");
            move(VARYING[1], ATTRIBUTE[2]);
        }
    }

    override protected function _fragmentShader():void {
        var zero:IComponent             = CONST[0].x;
        var half:IComponent             = CONST[0].y;
        var one:IComponent              = CONST[0].z;
        var two:IComponent              = CONST[0].w;
        var minU:IComponent             = _useVertexUVRange ? VARYING[1].x : CONST[3].x;
        var maxU:IComponent             = _useVertexUVRange ? VARYING[1].y : CONST[3].y;
        var minV:IComponent             = _useVertexUVRange ? VARYING[1].z : CONST[3].z;
        var maxV:IComponent             = _useVertexUVRange ? VARYING[1].w : CONST[3].w;
        var lightColor:IField           = CONST[1].rgb;
        var uvInput:IRegister           = TEMP[0];
        var uvHorizontal:IRegister      = TEMP[1];
        var uvVertical:IRegister        = TEMP[2];
        var uv:IRegister                = TEMP[3];
        var inputColor:IRegister        = TEMP[6];
        var outputColor:IRegister       = TEMP[7];
        var halfPixelWidth:IComponent   = CONST[2].z;
        var halfPixelHeight:IComponent  = CONST[2].w;

        move(uvInput, VARYING[0]);

        comment("uv -> [0, 1]");
        ShaderUtil.normalize(uvInput.x, minU, maxU, TEMP[4].x);
        ShaderUtil.normalize(uvInput.y, minV, maxV, TEMP[4].x);

        comment("create UVs for reading horizontal shadow distance and scale it to [minU, maxU] and [minV, maxV]");
        move(uvHorizontal, uvInput);
        normalizedToHorizontalUV(uvHorizontal, TEMP[4], half, one, two);
        ShaderUtil.scale(uvHorizontal.x, minU, maxU, TEMP[4].x);
        ShaderUtil.scale(uvHorizontal.y, minV, maxV, TEMP[4].x);
        ShaderUtil.clamp(uvHorizontal.x, minU, maxU, halfPixelWidth, TEMP[4]);
        ShaderUtil.clamp(uvHorizontal.y, minV, maxV, halfPixelHeight, TEMP[4]);

        comment("create UVs for reading vertical shadow distance and scale it to [minU, maxU] and [minV, maxV]");
        move(uvVertical, uvInput);
        normalizedToVerticalUV(uvVertical, TEMP[4], half, one, two);
        ShaderUtil.scale(uvVertical.x, minU, maxU, TEMP[4].x);
        ShaderUtil.scale(uvVertical.y, minV, maxV, TEMP[4].x);
        ShaderUtil.clamp(uvVertical.x, minU, maxU, halfPixelWidth, TEMP[4]);
        ShaderUtil.clamp(uvVertical.y, minV, maxV, halfPixelHeight, TEMP[4]);

        comment("create UVs in [-1, 1] and abs()");
        subtract(uvInput.z, uvInput.x, half);
        multiply(uvInput.z, uvInput.z, two);
        subtract(uvInput.w, uvInput.y, half);
        multiply(uvInput.w, uvInput.w, two);
        abs(uvInput.z, uvInput.z);
        abs(uvInput.w, uvInput.w);

        var comparison:String = Utils.GREATER_THAN;

        comment("sample horizontal or vertical shadow map");
        Utils.setByComparison(uv, uvInput.z, comparison, uvInput.w, uvHorizontal, uvVertical, TEMP[4]);
        sampleTexture(inputColor, uv, SAMPLER[0], [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_NEAREST, TextureFlag.MIP_NO]);

        comment("read shadow distance from the map and calculate current distance from texture's center");
        Utils.setByComparison(TEMP[5].x, uvInput.z, comparison, uvInput.w, inputColor.r, inputColor.g, TEMP[4]);
        distance(TEMP[5].y, uvInput.z, uvInput.w, TEMP[4].z, TEMP[4].w, zero, one, half);

        Utils.setByComparison(outputColor.rgb, TEMP[5].y, Utils.LESS_THAN, TEMP[5].x, zero, lightColor, TEMP[4]);

        comment("distance is encoded in range [0.5, 1], normalize it first");
        ShaderUtil.normalize(TEMP[5].y, half, one, TEMP[5].z);

        // TODO: fix this bug - diagonal values are incorrect
        //move(outputColor.rgb, TEMP[5].x);

        move(outputColor.a, one);

        move(OUTPUT, outputColor);
    }

    private static function distance(value:IComponent, x:IComponent, y:IComponent, tempX:IComponent, tempY:IComponent, zero:IComponent, one:IComponent, half:IComponent):void {
        ShaderUtil.distance(value, x, y, tempX, tempY);

        Utils.clamp(value, value, zero, one);
        subtract(value, one, value);

        multiply(value, half, value);
        add(value, half, value);
    }

    private function normalizedToHorizontalUV(uv:IRegister, temp:IRegister, half:IComponent, one:IComponent, two:IComponent):void {
        move(temp, uv);

        var u:IComponent = temp.x;
        var v:IComponent = temp.y;

        subtract(u, u, half);
        abs(u, u);
        multiply(u, u, two);

        multiply(v, v, two);
        subtract(v, v, one);
        divide(v, v, u);
        add(v, v, one);
        divide(v, v, two);

        move(uv.y, v);
    }

    private function normalizedToVerticalUV(uv:IRegister, temp:IRegister, half:IComponent, one:IComponent, two:IComponent):void {
        move(temp, uv);

        var u:IComponent = temp.y;
        var v:IComponent = temp.x;

        subtract(u, u, half);
        abs(u, u);
        multiply(u, u, two);

        multiply(v, v, two);
        subtract(v, v, one);
        divide(v, v, u);
        add(v, v, one);
        divide(v, v, two);

        move(uv.x, uv.y);
        move(uv.y, v);
    }
}
}
