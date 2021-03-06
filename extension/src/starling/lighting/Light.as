/**
 * User: booster
 * Date: 07/12/13
 * Time: 13:49
 */
package starling.lighting {
import starling.core.Starling;
import starling.core.starling_internal;
import starling.display.DisplayObject;
import starling.textures.Texture;

public class Light {
    private var _x:Number;
    private var _y:Number;
    private var _radius:Number;
    private var _parent:DisplayObject;

    private var _color:int          = 0xffffff;
    private var _attenuation:Number = 1.0;
    private var _resolution:Number  = 1.0;
    private var _centerBlur:Number  = 0.0;
    private var _edgeBlur:Number    = 1.0;

    public function Light(x:Number, y:Number, r:Number, parent:DisplayObject = null) {
        _x = x;
        _y = y;
        _radius = r;
        _parent = parent != null ? parent : Starling.current.stage;
    }

    /** The x coordinate of the light relative to the local coordinates of the parent. */
    public function get x():Number { return _x; }
    public function set x(value:Number):void { _x = value; }

    /** The y coordinate of the light relative to the local coordinates of the parent. */
    public function get y():Number { return _y; }
    public function set y(value:Number):void {_y = value; }

    /** The radius coordinate of the light relative to the local coordinates of the parent. */
    public function get radius():Number { return _radius; }
    public function set radius(value:Number):void { _radius = value; }

    /** How does the light source attenuate. 1.0 means linear attenuation. @default 1.0 */
    public function get attenuation():Number { return _attenuation; }
    public function set attenuation(value:Number):void { _attenuation = value; }

    /** The light's color. @default 0xFFFFFF */
    public function get color():int { return _color; }
    public function set color(value:int):void { _color = value; }

    /** The display object this light is attached to. */
    public function get parent():DisplayObject { return _parent; }
    public function set parent(value:DisplayObject):void { _parent = value; }

    /** Center blur of the light. Values above one increase blur strength, below decrease it. @default 0.0 */
    public function get centerBlur():Number { return _centerBlur; }
    public function set centerBlur(value:Number):void { _centerBlur = value; }

    /** Edge blur of the light. Values above one increase blur strength, below decrease it. @default 1.0 */
    public function get edgeBlur():Number { return _edgeBlur; }
    public function set edgeBlur(value:Number):void { _edgeBlur = value; }

    /** The resolution (quality) of this light. Higher values will create larger texture, lower a smaller one. @default 1.0*/
    public function get resolution():Number { return _resolution; }
    public function set resolution(value:Number):void {
        if (value <= 0) throw new ArgumentError("Resolution must be > 0");
        else _resolution = value;
    }
}
}
