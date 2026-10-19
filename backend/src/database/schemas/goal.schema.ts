import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types, Schema as MongooseSchema } from 'mongoose';

export type GoalDocument = Goal & Document;

export enum GoalStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned',
}

@Schema({ timestamps: true, collection: 'goals' })
export class Goal {
  _id: Types.ObjectId;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true })
  title: string;

  @Prop({ required: true, trim: true })
  category: string;

  @Prop({ required: true, min: 1 })
  durationDays: number;

  @Prop({ default: 1, min: 1 })
  currentDay: number;

  @Prop({
    type: String,
    enum: Object.values(GoalStatus),
    default: GoalStatus.ACTIVE,
    index: true,
  })
  status: GoalStatus;

  createdAt: Date;
  updatedAt: Date;
}

export const GoalSchema = SchemaFactory.createForClass(Goal);
