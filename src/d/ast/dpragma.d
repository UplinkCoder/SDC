module d.ast.dpragma;

import d.context.name;
import d.common.node;
import d.ast.identifier;

class Pragma(ItemType) : ItemType {
    Name id;

    AstTemplateArgument[] args;

    this(Location location, Name id, typeof(args) args) {
        super(location);
        this.id = id;
        this.args = args;
    }
}

